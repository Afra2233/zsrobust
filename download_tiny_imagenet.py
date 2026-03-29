import os
import time
import zipfile
from pathlib import Path
from typing import Optional

import requests

URL = "https://cs231n.stanford.edu/tiny-imagenet-200.zip"

# 改成你自己的可写目录
BASE_DIR = Path("/storage/hpc/07/zhang303/data")
ZIP_PATH = BASE_DIR / "tiny-imagenet-200.zip"
EXTRACT_ROOT = BASE_DIR
TARGET_DIR = BASE_DIR / "tiny-imagenet-200"

CHUNK_SIZE = 1024 * 1024  # 1MB


def touch_path(path: Path, ts: Optional[float] = None):
    if ts is None:
        ts = time.time()
    try:
        os.utime(str(path), (ts, ts))
    except FileNotFoundError:
        pass


def touch_tree(root: Path, ts: Optional[float] = None):
    if ts is None:
        ts = time.time()

    if not root.exists():
        return

    for dirpath, dirnames, filenames in os.walk(str(root)):
        for name in filenames:
            touch_path(Path(dirpath) / name, ts)
        for name in dirnames:
            touch_path(Path(dirpath) / name, ts)

    touch_path(root, ts)


def get_remote_file_size(url: str) -> Optional[int]:
    try:
        r = requests.head(url, allow_redirects=True, timeout=15)
        r.raise_for_status()
        size = r.headers.get("Content-Length")
        if size is None:
            return None
        return int(size)
    except Exception:
        return None


def download_with_resume(url: str, output_path: Path):
    output_path.parent.mkdir(parents=True, exist_ok=True)

    remote_size = get_remote_file_size(url)
    local_size = output_path.stat().st_size if output_path.exists() else 0

    if remote_size is not None and local_size == remote_size:
        print("[下载] 文件已完整存在，跳过下载: {}".format(output_path))
        touch_path(output_path)
        return

    headers = {}
    mode = "wb"

    if local_size > 0:
        headers["Range"] = "bytes={}-".format(local_size)
        mode = "ab"
        print("[下载] 检测到部分文件，继续下载: 已有 {} 字节".format(local_size))
    else:
        print("[下载] 开始全量下载")

    with requests.get(url, stream=True, headers=headers, timeout=30) as r:
        if r.status_code == 200 and local_size > 0:
            print("[下载] 服务器不支持断点续传，重新下载整个文件")
            mode = "wb"
            local_size = 0
        elif r.status_code not in (200, 206):
            r.raise_for_status()

        with open(str(output_path), mode) as f:
            downloaded = local_size
            total = remote_size if remote_size is not None else 0

            for chunk in r.iter_content(chunk_size=CHUNK_SIZE):
                if not chunk:
                    continue
                f.write(chunk)
                downloaded += len(chunk)

                if total > 0:
                    percent = downloaded * 100.0 / total
                    print(
                        "\r[下载] {}/{} bytes ({:.2f}%)".format(downloaded, total, percent),
                        end=""
                    )
                else:
                    print("\r[下载] {} bytes".format(downloaded), end="")

    print("\n[下载] 完成")
    touch_path(output_path)


def extract_with_resume(zip_path: Path, extract_root: Path):
    if not zip_path.exists():
        raise FileNotFoundError("压缩包不存在: {}".format(zip_path))

    extract_root.mkdir(parents=True, exist_ok=True)
    now_ts = time.time()

    print("[解压] 开始检查并继续解压 ...")
    with zipfile.ZipFile(str(zip_path), "r") as zf:
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

            # 已存在且大小一致则跳过
            if target_path.exists() and target_path.stat().st_size == member.file_size:
                touch_path(target_path, now_ts)
                print(
                    "\r[解压] 跳过已完成文件 {}/{}: {}".format(i, total, member.filename),
                    end=""
                )
                continue

            # zip 里单个文件不能真正半截续解，这里按文件粒度补解压
            with zf.open(member, "r") as src, open(str(target_path), "wb") as dst:
                while True:
                    chunk = src.read(CHUNK_SIZE)
                    if not chunk:
                        break
                    dst.write(chunk)

            touch_path(target_path, now_ts)
            print(
                "\r[解压] 已完成 {}/{}: {}".format(i, total, member.filename),
                end=""
            )

    print("\n[解压] 全部完成")

    if TARGET_DIR.exists():
        touch_tree(TARGET_DIR, time.time())


def main():
    BASE_DIR.mkdir(parents=True, exist_ok=True)

    download_with_resume(URL, ZIP_PATH)
    extract_with_resume(ZIP_PATH, EXTRACT_ROOT)

    touch_path(ZIP_PATH)
    if TARGET_DIR.exists():
        touch_path(TARGET_DIR)

    print("[完成] zip: {}".format(ZIP_PATH))
    print("[完成] 数据目录: {}".format(TARGET_DIR))


if __name__ == "__main__":
    main()