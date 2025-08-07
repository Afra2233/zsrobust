#!/bin/bash
#SBATCH --job-name=PMG_AFT           # 任务名
#SBATCH --output=logs/pmg_%j.out     # 输出日志文件（%j 是 job id）
#SBATCH --error=logs/pmg_%j.err      # 错误日志文件
#SBATCH --time=24:00:00              # 运行最长时间（可调整）
#SBATCH --partition=gpu              # 分区（如有）
#SBATCH --gres=gpu:1                 # 请求一个 GPU
#SBATCH --cpus-per-task=8            # 请求 CPU 数量
#SBATCH --mem=32G                    # 请求内存



# module load anaconda3/2022.05


source ~/.bashrc
conda activate /scratch/hpc/07/zhang303/conda_envs/zsrobust

# 进入项目目录
cd ~/zsrobust

# 运行脚本
python PMG_AFT.py \
    --batch_size 256 \
    --root ./data \
    --dataset tinyImageNet \
    --name wangsibo \
    --train_eps 1 \
    --train_numsteps 2 \
    --train_stepsize 1
