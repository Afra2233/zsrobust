#!/bin/bash
#SBATCH --job-name=unzip_tiny
#SBATCH -p parallel              
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=96G
#SBATCH --chdir=/scratch/hpc/07/zhang303/zsrobust
#SBATCH --output=logs/unzip_tiny_%j.out
#SBATCH --error=logs/unzip_tiny_%j.err

#!/bin/bash
#SBATCH --job-name=unzip_tiny
#SBATCH -p parallel              
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --chdir=/scratch/hpc/07/zhang303/zsrobust
#SBATCH --output=logs/unzip_tiny_%j.out
#SBATCH --error=logs/unzip_tiny_%j.err

set -euo pipefail

mkdir -p logs data
cd data || exit 1

echo "[INFO] 解压 tiny-imagenet-200.zip ..."
unzip -o -q tiny-imagenet-200.zip -d .

# 整理验证集
VAL_DIR="tiny-imagenet-200/val"
if [ -d "$VAL_DIR/images" ] && [ -f "$VAL_DIR/val_annotations.txt" ]; then
    echo "[INFO] 整理验证集目录结构 ..."
    awk '{print $1, $2}' "$VAL_DIR/val_annotations.txt" | while read -r IMG WNID; do
        mkdir -p "$VAL_DIR/$WNID"
        mv "$VAL_DIR/images/$IMG" "$VAL_DIR/$WNID/" 2>/dev/null || true
    done
    rmdir "$VAL_DIR/images" 2>/dev/null || true
fi

# 刷新时间戳
find tiny-imagenet-200 -type f -exec touch -m {} +

# 完整性检查（只算 JPEG 图片）
train_count=$(find tiny-imagenet-200/train -type f -name "*.JPEG" | wc -l)
val_count=$(find tiny-imagenet-200/val   -type f -name "*.JPEG" | wc -l)

echo "[INFO] train JPEG files: $train_count (期望 100000)"
echo "[INFO] val   JPEG files: $val_count (期望 10000)"

if [ "$train_count" -ne 100000 ] || [ "$val_count" -ne 10000 ]; then
    echo "[ERROR] 解压或整理不完整"; exit 1
fi

echo "[DONE] 解压 & 验证完成 ✅"

