#!/bin/bash
set -euo pipefail

# === 配置你的路径（按需改）===
SRC="/scratch/hpc/07/zhang303/zsrobust/replace"
ENV="/storage/hpc/07/zhang303/conda_envs/zsrobust39"
SITE="$ENV/lib/python3.9/site-packages"

echo "[INFO] 源(仓库) replace 路径: $SRC"
echo "[INFO] 目标(环境) site-packages: $SITE"
echo

# === 简单存在性检查 ===
for p in "$SRC/clip.py" "$SRC/model.py" "$SRC/torchvision.datasets"; do
  [[ -e "$p" ]] || { echo "[ERR] 缺少 $p"; exit 1; }
done
for d in "$SITE/clip" "$SITE/torchvision/datasets"; do
  [[ -d "$d" ]] || { echo "[ERR] 目标目录不存在: $d"; exit 1; }
done

# === 备份（可回滚）===
BK="$HOME/backup_replace_$(date +%F_%H%M%S)"
mkdir -p "$BK"
echo "[INFO] 备份到: $BK"
cp -v "$SITE/clip/clip.py"  "$BK/clip.py.bak"   || true
cp -v "$SITE/clip/model.py" "$BK/model.py.bak"  || true
mkdir -p "$BK/datasets_bak"
cp -vr "$SITE/torchvision/datasets" "$BK/datasets_bak/" >/dev/null 2>&1 || true
echo

# === 执行覆盖 ===
echo "[INFO] 覆盖 CLIP 源码 ..."
cp -v "$SRC/clip.py"  "$SITE/clip/clip.py"
cp -v "$SRC/model.py" "$SITE/clip/model.py"

echo "[INFO] 覆盖 torchvision.datasets ..."
cp -vr "$SRC/torchvision.datasets/"* "$SITE/torchvision/datasets/"

# === 清理 .pyc，避免旧缓存 ===
find "$SITE/clip" -name "*.pyc" -delete || true
find "$SITE/torchvision/datasets" -name "*.pyc" -delete || true
echo

# === 校验 1：哈希一致性（源 vs 目标）===
echo "[INFO] 计算哈希以比对（源 vs 目标）..."
echo "clip.py    :"
sha1sum "$SRC/clip.py"  "$SITE/clip/clip.py"  | sed 's|'"$SRC"'\||; s|'"$SITE"'\||'
echo "model.py   :"
sha1sum "$SRC/model.py" "$SITE/clip/model.py" | sed 's|'"$SRC"'\||; s|'"$SITE"'\||'
echo

# === 校验 2：Python 导入路径确认 ===
echo "[INFO] Python 导入路径确认："
python - <<'PY'
import inspect, clip, torchvision
print("clip 包入口   ->", clip.__file__)
from clip import model as _m
print("clip.model.py ->", inspect.getsourcefile(_m))
import torchvision.datasets as d
print("torchvision.datasets ->", d.__file__)
PY
echo

echo "[DONE] 替换完成。备份在: $BK"
