#!/bin/bash
#SBATCH --job-name=PMG_AFT
#SBATCH --output=logs/pmg_%j.out
#SBATCH --error=logs/pmg_%j.err
#SBATCH -p gpu-medium
#SBATCH --gres=gpu:1 
#SBATCH --time=04:00:00
#SBATCH --mem=96G
#SBATCH --cpus-per-task=8


# module load anaconda3/2022.05


source ~/.bashrc
conda activate /scratch/hpc/07/zhang303/conda_envs/zsrobust

# 进入项目目录
# cd ~/zsrobust
cd /scratch/hpc/07/zhang303/zsrobust

# 运行脚本
python PMG_AFT.py \
    --batch_size 256 \
    --root ./data \
    --dataset tinyImageNet \
    --name wangsibo \
    --train_eps 1 \
    --train_numsteps 2 \
    --train_stepsize 1
