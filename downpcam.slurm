#!/bin/bash
#SBATCH --job-name=get_pcam
#SBATCH -p serial            # HEC上下载最好用轻量队列/serial队列，别占GPU队列
#SBATCH --time=10:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --chdir=/scratch/hpc/07/zhang303/zsrobust
#SBATCH --output=logs/get_pcam_%j.out
#SBATCH --error=logs/get_pcam_%j.err
set -euo pipefail
BASE=/scratch/hpc/07/zhang303/zsrobust/data/pcam
mkdir -p "$BASE"; cd "$BASE"
python3 -m pip install --user -q gdown
~/.local/bin/gdown 1Ka0XfEMiwgCYPdTI-vv6eUElOBnKFKQ2 -O camelyonpatch_level_2_split_train_x.h5.gz
~/.local/bin/gdown 1269yhu3pZDP8UYFQs-NYs3FPwuK-nGSG -O camelyonpatch_level_2_split_train_y.h5.gz
~/.local/bin/gdown 1qV65ZqZvWzuIVthK8eVDhIwrbnsJdbg_ -O camelyonpatch_level_2_split_test_x.h5.gz
~/.local/bin/gdown 17BHrSrwWKjYsOgTMmoqrIjDy6Fa2o_gP -O camelyonpatch_level_2_split_test_y.h5.gz
~/.local/bin/gdown 1hgshYGWK8V-eGRy8LToWJJgDU_rXWVJ3 -O camelyonpatch_level_2_split_valid_x.h5.gz
~/.local/bin/gdown 1bH8ZRbhSVAhScTS0p9-ZzGnX91cHT3uO -O camelyonpatch_level_2_split_valid_y.h5.gz
gunzip -f *.gz
echo "[DONE] PCAM ready at $BASE"
EOF
sbatch jobs/get_pcam.sbatch
