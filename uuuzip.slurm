#!/bin/bash
#SBATCH --job-name=unzip_tiny
#SBATCH -p parallel              
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=96G
#SBATCH --chdir=/scratch/hpc/07/zhang303/zsrobust
#SBATCH --output=logs/unzip_tiny_%j.out
#SBATCH --error=logs/unzip_tiny_%j.err

# 确保目录存在
mkdir -p logs data
cd data || exit 1

echo "[INFO] 解压 tiny-imagenet-200.zip ..."
unzip -o -q tiny-imagenet-200.zip -d .

echo "[INFO] 刷新时间戳 ..."
find tiny-imagenet-200 -type f -exec touch -m {} +

# 简单完整性检查
train_count=$(find tiny-imagenet-200/train -type f | wc -l)
val_count=$(find tiny-imagenet-200/val -type f | wc -l)
echo "[INFO] train files: $train_count"
echo "[INFO] val files:   $val_count"

# 非零则认为成功
if [ "$train_count" -eq 0 ] || [ "$val_count" -eq 0 ]; then
  echo "[ERROR] 解压不完整"; exit 1
fi

echo "[DONE] 解压完成 ✅"


