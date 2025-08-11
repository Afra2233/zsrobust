#!/bin/bash
#SBATCH --job-name=unzip_tiny
#SBATCH --output=logs/unzip_tiny_%j.out
#SBATCH --error=logs/unzip_tiny_%j.err
#SBATCH -p cpu-short
#SBATCH --time=04:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=2

# 1. 进入数据目录
cd /scratch/hpc/07/zhang303/zsrobust/data || exit 1

# 2. 解压（覆盖同名文件）
echo "开始解压 tiny-imagenet-200.zip ..."
unzip -o tiny-imagenet-200.zip -d . -q

# 3. 更新所有文件的时间戳
echo "更新 tiny-imagenet-200 时间戳..."
find tiny-imagenet-200 -type f -exec touch {} +

# 4. 检查文件数量
train_count=$(find tiny-imagenet-200/train -type f | wc -l)
val_count=$(find tiny-imagenet-200/val -type f | wc -l)
echo "训练集图片数: $train_count"
echo "验证集图片数: $val_count"

echo "解压完成 ✅"
