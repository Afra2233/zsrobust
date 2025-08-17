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
cd data || exit 1

echo "[INFO] 解压 tiny-imagenet-200.zip ..."
unzip -o -q tiny-imagenet-200.zip -d .

# 整理验证集目录结构（把 val/images 下的图按 WNID 分到各类目录）
VAL_DIR="tiny-imagenet-200/val"
if [ -d "$VAL_DIR/images" ] && [ -f "$VAL_DIR/val_annotations.txt" ]; then
  echo "[INFO] 整理验证集目录结构 ..."
  awk '{print $1, $2}' "$VAL_DIR/val_annotations.txt" | while read -r IMG WNID; do
    mkdir -p "$VAL_DIR/$WNID"
    mv "$VAL_DIR/images/$IMG" "$VAL_DIR/$WNID/" 2>/dev/null || true
  done
  rmdir "$VAL_DIR/images" 2>/dev/null || true
fi

# 刷新时间戳（可选）

find tiny-imagenet-200 -exec touch {} +
# ===== 基本完整性检查 =====
train_count=$(find tiny-imagenet-200/train -type f -iname "*.jpeg" | wc -l)
val_count=$(find tiny-imagenet-200/val   -type f -iname "*.jpeg" | wc -l)
train_cls=$(find tiny-imagenet-200/train -mindepth 1 -maxdepth 1 -type d | wc -l)
val_cls=$(find tiny-imagenet-200/val   -mindepth 1 -maxdepth 1 -type d | wc -l)

echo "[INFO] train classes: $train_cls (期望 200)"
echo "[INFO] val   classes: $val_cls   (期望 200)"
echo "[INFO] train JPEG files: $train_count (期望 100000)"
echo "[INFO] val   JPEG files: $val_count   (期望 10000)"

if [ "$train_cls" -ne 200 ] || [ "$val_cls" -ne 200 ] || [ "$train_count" -ne 100000 ] || [ "$val_count" -ne 10000 ]; then
  echo "[ERROR] 类别数或图片总数不符合期望"; exit 1
fi

# ===== 严格逐类检查（train 每类=500，val 每类=50）=====
echo "[INFO] 逐类检查 train=500/val=50 ..."
bad_train=0
bad_val=0
while read -r d; do
  c=$(find "$d/images" -type f -iname "*.jpeg" | wc -l)
  if [ "$c" -ne 500 ]; then
    echo "[WARN] $(basename "$d") train 有 $c 张 (期望 500)"
    bad_train=1
  fi
done < <(find tiny-imagenet-200/train -mindepth 1 -maxdepth 1 -type d)

while read -r d; do
  c=$(find "$d" -type f -iname "*.jpeg" | wc -l)
  if [ "$c" -ne 50 ]; then
    echo "[WARN] $(basename "$d") val 有 $c 张 (期望 50)"
    bad_val=1
  fi
done < <(find tiny-imagenet-200/val -mindepth 1 -maxdepth 1 -type d)

if [ "$bad_train" -ne 0 ] || [ "$bad_val" -ne 0 ]; then
  echo "[ERROR] 按类计数不匹配，请检查上面的 WARN 列表"; exit 1
fi

echo "[DONE] 解压 & 验证完成 ✅"
