#!/bin/bash
set -e  # 出错就退出

# 你的 conda 环境路径
ENV_PATH="/storage/hpc/07/zhang303/conda_envs/zsrobust39"
SITE="$ENV_PATH/lib/python3.9/site-packages"

echo "[INFO] 激活环境..."
source /etc/profile
conda activate "$ENV_PATH"

echo "[INFO] 开始替换 clip.py 和 model.py..."
cp replace/clip.py "$SITE/clip/clip.py"
cp replace/model.py "$SITE/clip/model.py"

echo "[INFO] 开始替换 torchvision.datasets..."
cp -r replace/torchvision.datasets/* "$SITE/torchvision/datasets/"

echo "[DONE] 所有文件已替换 ✅"
