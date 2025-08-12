#!/bin/bash
#SBATCH --job-name=resume_unzip_Image_strict
#SBATCH -p parallel
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=96G
#SBATCH --chdir=/scratch/hpc/07/zhang303/zsrobust/data/Imagenet
#SBATCH --output=logs/resume_unzip_Image_strict_%j.out
#SBATCH --error=logs/resume_unzip_Image_strict_%j.err

set -euo pipefail
source /etc/profile

mkdir -p train

echo "[INFO] Strict resume of ImageNet train extraction..."

# 统计未完成 tar 包总数（作为总进度基准）
total_classes=$(ls train/*.tar 2>/dev/null | wc -l || true)
done_classes=0

# 帮助函数：生成规范化的“文件名清单”
# 1) 从 tar 内部列出应有图片文件，取 basename，转成有序去重列表
# 2) 从目录中列出已解压图片文件，取 basename，转成有序去重列表
mk_lists() {
  local tarfile="$1"
  local outdir="$2"

  # 期望清单（expected）
  tar -tf "$tarfile" \
    | grep -Ei '\.(jpe?g|png|bmp|tiff?)$' \
    | sed 's#.*/##' \
    | sort -u > "$outdir/.expected.list"

  # 实际清单（actual）
  # 用 -print0 + xargs -0 确保文件名安全
  find "$outdir" -type f -iregex '.*\.\(jpe\?g\|png\|bmp\|tiff\?\)$' -print0 \
    | xargs -0 -n1 basename \
    | sort -u > "$outdir/.actual.list" || true
}

for x in train/*.tar; do
  # 类别目录（与 tar 同名去掉 .tar）
  cls="${x%.tar}"
  mkdir -p "$cls"

  # 统计 tar 内应有图片总数
  exp=$(tar -tf "$x" | grep -Ei '\.(jpe?g|png|bmp|tiff?)$' | wc -l || true)

  # 生成 expected/actual 清单
  mk_lists "$x" "$cls"

  have=$(wc -l < "$cls/.actual.list" || echo 0)
  if [ "$exp" -eq 0 ]; then
    echo "[WARN] $(basename "$cls") tar has 0 images? Skipping delete to be safe."
    continue
  fi

  # 计算缺失文件清单（expected - actual）
  comm -23 "$cls/.expected.list" "$cls/.actual.list" > "$cls/.missing.list" || true
  missing=$(wc -l < "$cls/.missing.list" || echo 0)

  if [ -f "$cls/.done" ] || { [ "$missing" -eq 0 ] && [ "$have" -ge "$exp" ]; }; then
    touch "$cls/.done"
    rm -f "$x" 2>/dev/null || true
    ((done_classes++))
    echo "[SKIP] $(basename "$cls") complete ($have/$exp). Progress: $done_classes/$total_classes"
    continue
  fi

  echo "[EXTRACT] $(basename "$cls") missing=$missing ($have/$exp -> $exp). Re-extracting to heal..."
  # 直接整体重解压（覆盖可能的残缺），并刷新时间戳
  tar -xvmf "$x" -C "$cls" -m

  # 重新核对
  mk_lists "$x" "$cls"
  have=$(wc -l < "$cls/.actual.list" || echo 0)
  comm -23 "$cls/
