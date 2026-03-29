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
#SBATCH --job-name=tiny_download_unzip
#SBATCH -p parallel
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=96G
#SBATCH --chdir=/scratch/hpc/07/zhang303/zsrobust


set -euo pipefail

mkdir -p logs data
cd data || exit 1

ZIP_NAME="tiny-imagenet-200.zip"
DATA_DIR="tiny-imagenet-200"
URL="http://cs231n.stanford.edu/tiny-imagenet-200.zip"

echo "[INFO] 工作目录: $(pwd)"
echo "[INFO] 时间: $(date)"

# ===== 第一步：下载（支持断点续传）=====
if [ -f "$ZIP_NAME" ]; then
  echo "[INFO] 已发现 $ZIP_NAME ，尝试断点续传下载 ..."
else
  echo "[INFO] 未发现 $ZIP_NAME ，开始下载 ..."
fi

wget -c --progress=bar:force -O "$ZIP_NAME" "$URL"

if [ ! -f "$ZIP_NAME" ]; then
  echo "[ERROR] 下载失败，未找到 $ZIP_NAME"
  exit 1
fi

echo "[INFO] 下载完成"
ls -lh "$ZIP_NAME"

# ===== 第二步：解压（支持补全之前未完成的解压）=====
echo "[INFO] 开始解压/补全解压 ..."
unzip -o "$ZIP_NAME" -d .

if [ ! -d "$DATA_DIR" ]; then
  echo "[ERROR] 解压失败，未找到目录 $DATA_DIR"
  exit 1
fi

echo "[INFO] 解压完成，当前目录结构检查："
find "$DATA_DIR" -maxdepth 2 -type d | head -n 20

# ===== 第三步：整理验证集目录结构 =====
VAL_DIR="$DATA_DIR/val"
if [ -d "$VAL_DIR/images" ] && [ -f "$VAL_DIR/val_annotations.txt" ]; then
  echo "[INFO] 整理验证集目录结构 ..."
  awk '{print $1, $2}' "$VAL_DIR/val_annotations.txt" | while read -r IMG WNID; do
    mkdir -p "$VAL_DIR/$WNID"
    if [ -f "$VAL_DIR/images/$IMG" ]; then
      mv "$VAL_DIR/images/$IMG" "$VAL_DIR/$WNID/"
    fi
  done
  rmdir "$VAL_DIR/images" 2>/dev/null || true
else
  echo "[INFO] 验证集目录似乎已经整理过，跳过整理步骤"
fi

# ===== 刷新时间戳（可选）=====
find "$DATA_DIR" -exec touch {} + || true

# ===== 基本完整性检查 =====
train_count=$(find "$DATA_DIR/train" -type f -iname "*.jpeg" | wc -l)
val_count=$(find "$DATA_DIR/val"   -type f -iname "*.jpeg" | wc -l)
train_cls=$(find "$DATA_DIR/train" -mindepth 1 -maxdepth 1 -type d | wc -l)
val_cls=$(find "$DATA_DIR/val"     -mindepth 1 -maxdepth 1 -type d | wc -l)

echo "[INFO] train classes: $train_cls (期望 200)"
echo "[INFO] val   classes: $val_cls   (期望 200)"
echo "[INFO] train JPEG files: $train_count (期望 100000)"
echo "[INFO] val   JPEG files: $val_count   (期望 10000)"

# ===== 严格逐类检查（train 每类=500，val 每类=50）=====
echo "[INFO] 逐类检查 train=500 / val=50 ..."
bad_train=0
bad_val=0

while read -r d; do
  c=$(find "$d/images" -type f -iname "*.jpeg" | wc -l)
  if [ "$c" -ne 500 ]; then
    echo "[WARN] $(basename "$d") train 有 $c 张 (期望 500)"
    bad_train=1
  fi
done < <(find "$DATA_DIR/train" -mindepth 1 -maxdepth 1 -type d)

while read -r d; do
  c=$(find "$d" -type f -iname "*.jpeg" | wc -l)
  if [ "$c" -ne 50 ]; then
    echo "[WARN] $(basename "$d") val 有 $c 张 (期望 50)"
    bad_val=1
  fi
done < <(find "$DATA_DIR/val" -mindepth 1 -maxdepth 1 -type d)

# ===== 最终判定 =====
if [ "$train_cls" -ne 200 ] || [ "$val_cls" -ne 200 ] || [ "$train_count" -ne 100000 ] || [ "$val_count" -ne 10000 ]; then
  echo "[ERROR] 类别数或图片总数不符合期望"
  exit 1
fi

if [ "$bad_train" -ne 0 ] || [ "$bad_val" -ne 0 ]; then
  echo "[ERROR] 按类计数不匹配，请检查上面的 WARN 列表"
  exit 1
fi

echo "[DONE] 下载、解压与验证完成 ✅"
echo "[INFO] 完成时间: $(date)"