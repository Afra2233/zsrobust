#!/bin/bash
#SBATCH --job-name=unzip_tiny
#SBATCH -p parallel              
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=96G
#SBATCH --chdir=/scratch/hpc/07/zhang303/zsrobust
#SBATCH --output=logs/unzip_tiny_%j.out
#SBATCH --error=logs/unzip_tiny_%j.err


set -euo pipefail

mkdir -p logs data
cd data

ZIP=tiny-imagenet-200.zip
URL=http://cs231n.stanford.edu/tiny-imagenet-200.zip
ROOT=tiny-imagenet-200

echo "[INFO] 下载 ${ZIP} ..."
# -c 断点续传；--tries 重试；--timeout 超时(秒)
wget -c --tries=10 --timeout=30 "${URL}"

echo "[INFO] 解压 ${ZIP} ..."
# -o 覆盖；-q 安静；-d 指定目录
unzip -o -q "${ZIP}" -d .

# 如果 val 还没被整理，则进行整理
if [ -d "${ROOT}/val/images" ] && [ -f "${ROOT}/val/val_annotations.txt" ]; then
  echo "[INFO] 整理 val 目录到按类别结构 ..."
  pushd "${ROOT}/val" >/dev/null

  # 建立类别子目录并移动对应图片
  awk '{print $1, $2}' val_annotations.txt | while read -r IMG WNID; do
    mkdir -p "${WNID}"
    if [ -f "images/${IMG}" ]; then
      mv "images/${IMG}" "${WNID}/"
    fi
  done

  # 清理空目录
  rmdir images 2>/dev/null || true
  popd >/dev/null
fi

# 刷新时间戳（可选）
find "${ROOT}" -type f -exec touch -m {} +

echo "[INFO] 进行完整性检查 ..."
# Tiny ImageNet 的图片扩展名是 .JPEG（大写）
train_jpg=$(find "${ROOT}/train" -type f -name "*.JPEG" | wc -l)
val_jpg=$(find "${ROOT}/val"   -type f -name "*.JPEG" | wc -l)

echo "[INFO] train JPEG files: ${train_jpg} (期望 100000)"
echo "[INFO] val   JPEG files: ${val_jpg} (期望 10000)"

if [ "${train_jpg}" -ne 100000 ] || [ "${val_jpg}" -ne 10000 ]; then
  echo "[ERROR] 文件数量不符合预期，请检查网络或解压过程。"
  exit 1
fi

echo "[DONE] Tiny ImageNet-200 准备完成 ✅"
echo "[TIP] 之后可用 torchvision.datasets.ImageFolder(root='.../tiny-imagenet-200/train') 和 root='.../tiny-imagenet-200/val'"
# 确保目录存在
# mkdir -p logs data
# cd data || exit 1

# echo "[INFO] 下载 tiny-imagenet-200.zip ..."
# wget http://cs231n.stanford.edu/tiny-imagenet-200.zip

# echo "[INFO] 解压 tiny-imagenet-200.zip ..."
# unzip -o -q tiny-imagenet-200.zip -d .

# echo "[INFO] 刷新时间戳 ..."
# find tiny-imagenet-200 -type f -exec touch -m {} +

# # 简单完整性检查
# train_count=$(find tiny-imagenet-200/train -type f | wc -l)
# val_count=$(find tiny-imagenet-200/val -type f | wc -l)
# echo "[INFO] train files: $train_count"
# echo "[INFO] val files:   $val_count"

# # 非零则认为成功
# if [ "$train_count" -eq 0 ] || [ "$val_count" -eq 0 ]; then
#   echo "[ERROR] 解压不完整"; exit 1
# fi

# echo "[DONE] 解压完成 ✅"


