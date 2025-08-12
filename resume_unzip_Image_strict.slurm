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
# 打印每条命令（便于追踪），可以注释掉
set -x

# 确保工作目录和日志目录存在（有些 Slurm 在 chdir 前就尝试打开日志文件）
mkdir -p /scratch/hpc/07/zhang303/zsrobust/data/Imagenet
cd /scratch/hpc/07/zhang303/zsrobust/data/Imagenet
mkdir -p logs train

echo "[BOOT] $(date) job started on $(hostname)"

# 函数：生成 expected/actual 清单（按文件名校验）
mk_lists() {
  local tarfile="$1"
  local outdir="$2"

  tar -tf "$tarfile" \
    | grep -Ei '\.(jpe?g|png|bmp|tiff?)$' \
    | sed 's#.*/##' \
    | sort -u > "$outdir/.expected.list"

  find "$outdir" -type f -iregex '.*\.\(jpe\?g\|png\|bmp\|tiff\?\)$' -print0 \
    | xargs -0 -n1 basename 2>/dev/null \
    | sort -u > "$outdir/.actual.list" || true
}

echo "[INFO] Strict resume of ImageNet train extraction..."

total_classes=$(ls train/*.tar 2>/dev/null | wc -l || true)
done_classes=0

shopt -s nullglob
for x in train/*.tar; do
  cls="${x%.tar}"
  mkdir -p "$cls"

  exp=$(tar -tf "$x" | grep -Ei '\.(jpe?g|png|bmp|tiff?)$' | wc -l || true)
  if [ "${exp:-0}" -eq 0 ]; then
    echo "[WARN] $(basename "$cls") tar has 0 images? skip delete to be safe."
    continue
  fi

  mk_lists "$x" "$cls"
  have=$(wc -l < "$cls/.actual.list" || echo 0)
  comm -23 "$cls/.expected.list" "$cls/.actual.list" > "$cls/.missing.list" || true
  missing=$(wc -l < "$cls/.missing.list" || echo 0)

  if [ -f "$cls/.done" ] || { [ "$missing" -eq 0 ] && [ "$have" -ge "$exp" ]; }; then
    touch "$cls/.done"
    rm -f "$x" 2>/dev/null || true
    ((done_classes++))
    echo "[SKIP] $(basename "$cls") complete ($have/$exp). Progress: $done_classes/$total_classes"
    continue
  fi

  echo "[EXTRACT] $(basename "$cls") missing=$missing ($have/$exp -> $exp). Re-extracting..."
  tar -xvmf "$x" -C "$cls" -m

  mk_lists "$x" "$cls"
  have=$(wc -l < "$cls/.actual.list" || echo 0)
  comm -23 "$cls/.expected.list" "$cls/.actual.list" > "$cls/.missing.list" || true
  missing=$(wc -l < "$cls/.missing.list" || echo 0)

  if [ "$missing" -eq 0 ] && [ "$have" -ge "$exp" ]; then
    touch "$cls/.done"
    rm -f "$x"
    ((done_classes++))
    echo "[OK] $(basename "$cls") complete ($have/$exp). Progress: $done_classes/$total_classes"
  else
    echo "[PENDING] $(basename "$cls") still incomplete ($have/$exp, missing=$missing). Keeping tar for next run."
  fi
done

left=$(( total_classes - done_classes ))
pct=0
if [ "$total_classes" -gt 0 ]; then
  pct=$(( 100 * done_classes / total_classes ))
fi
echo "[INFO] Finished pass. Done=$done_classes/$total_classes (${pct}%) Left=$left"
echo "[DONE] $(date)"
