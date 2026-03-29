import os
import time
import zipfile
from pathlib import Path

import requests

URL = "https://cs231n.stanford.edu/tiny-imagenet-200.zip"

BASE_DIR = Path("/data")
ZIP_PATH = BASE_DIR / "tiny-imagenet-200.zip"
EXTRACT_ROOT = BASE_DIR
TARGET_DIR = BASE_DIR / "tiny-imagenet-200"

CHUNK_SIZE = 1024 * 1024  # 1MB


def touch_path(path: Path, ts: float | None = None):
    """把文件或目录时间戳改成当前时间。"""
    if ts is None:
        ts = time.time()
    try:
        os.utime(path, (ts, ts))
    except FileNotFoundError:
        pass


def touch_tree(root: Path, ts: float | None = None):
    """递归更新整个目录树的时间戳。"""
    if ts is None:
        ts = time.time()

    if not root.exists():
        return

    for dirpath, dirnames, filenames in os.walk(root):
        for name in filenames:
            touch_path(Path(dirpath) / name, ts)
        for name in dirnames:
            touch_path(Path(dirpath) / name, ts)

    touch_path(root, ts)


def get_remote_file_size(url: str) -> int | None:
    try:
        r = requests.head(url, allow_redirects=True, timeout=15)
        r.raise_for_status()
        size = r.headers.get("Content-Length")
        return int(size) if size is not None else None
    except Exception:
        return None


def download_with_resume(url: str, output_path: Path):
    output_path.parent.mkdir(parents=True, exist_ok=True)

    remote_size = get_remote_file_size(url)
    local_size = output_path.stat().st_size if output_path.exists() else 0

    if remote_size is not None and local_size == remote_size:
        print(f"[下载] 文件已完整存在，跳过下载: {output_path}")
        touch_path(output_path)
        return

    headers = {}
    mode = "wb"

    if local_size > 0:
        headers["Range"] = f"bytes={local_size}-"
        mode = "ab"
        print(f"[下载] 检测到部分文件，继续下载: 已有 {local_size} 字节")
    else:
        print("[下载] 开始全量下载")

    with requests.get(url, stream=True, headers=headers, timeout=30) as r:
        if r.status_code == 200 and local_size > 0:
            print("[下载] 服务器不支持断点续传，重新下载整个文件")
            mode = "wb"
            local_size = 0
        elif r.status_code not in (200, 206):
            r.raise_for_status()

        with open(output_path, mode) as f:
            downloaded = local_size
            total = remote_size if remote_size is not None else 0

            for chunk in r.iter_content(chunk_size=CHUNK_SIZE):
                if not chunk:
                    continue
                f.write(chunk)
                downloaded += len(chunk)

                if total > 0:
                    percent = downloaded * 100 / total
                    print(f"\r[下载] {downloaded}/{total} bytes ({percent:.2f}%)", end="")
                else:
                    print(f"\r[下载] {downloaded} bytes", end="")

    print("\n[下载] 完成")
    touch_path(output_path)


def extract_with_resume(zip_path: Path, extract_root: Path):
    if not zip_path.exists():
        raise FileNotFoundError(f"压缩包不存在: {zip_path}")

    extract_root.mkdir(parents=True, exist_ok=True)
    now_ts = time.time()

    print("[解压] 开始检查并继续解压 ...")
    with zipfile.ZipFile(zip_path, "r") as zf:
        members = zf.infolist()
        total = len(members)

        for i, member in enumerate(members, 1):
            target_path = extract_root / member.filename

            if member.is_dir():
                target_path.mkdir(parents=True, exist_ok=True)
                touch_path(target_path, now_ts)
                continue

            target_path.parent.mkdir(parents=True, exist_ok=True)
            touch_path(target_path.parent, now_ts)

            # 如果文件已存在且大小一致，认为已完成，跳过
            if target_path.exists() and target_path.stat().st_size == member.file_size:
                touch_path(target_path, now_ts)
                print(f"\r[解压] 跳过已完成文件 {i}/{total}: {member.filename}", end="")
                continue

            # zip 内单个文件不能做真正的字节级续解压，所以未完成文件重新解这个文件
            with zf.open(member, "r") as src, open(target_path, "wb") as dst:
                while True:
                    chunk = src.read(CHUNK_SIZE)
                    if not chunk:
                        break
                    dst.write(chunk)

            touch_path(target_path, now_ts)
            print(f"\r[解压] 已完成 {i}/{total}: {member.filename}", end="")

    print("\n[解压] 全部完成")

    # 最后统一把整个目录树时间戳刷新成最新
    extracted_dir = extract_root / "tiny-imagenet-200"
    if extracted_dir.exists():
        touch_tree(extracted_dir, time.time())


def main():
    BASE_DIR.mkdir(parents=True, exist_ok=True)

    download_with_resume(URL, ZIP_PATH)
    extract_with_resume(ZIP_PATH, EXTRACT_ROOT)

    # 再确保 zip 本身也是最新时间戳
    touch_path(ZIP_PATH)

    print(f"[完成] zip: {ZIP_PATH}")
    print(f"[完成] 数据目录: {TARGET_DIR}")


if __name__ == "__main__":
    main()