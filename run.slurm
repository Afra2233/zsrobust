#!/bin/bash
#SBATCH --job-name=PMG_AFT
#SBATCH --output=logs/pmg_%j.out
#SBATCH --error=logs/pmg_%j.err
#SBATCH -p gpu-medium
#SBATCH --nodes=2
#SBATCH --gres=gpu:4 
#SBATCH --time=48:00:00
#SBATCH --mem=96G
#SBATCH --cpus-per-task=8


# module load anaconda3/2022.05


source ~/.bashrc
conda activate /storage/hpc/07/zhang303/conda_envs/zsrobust39

# 进入项目目录
# cd ~/zsrobust
cd /scratch/hpc/07/zhang303/zsrobust

# 运行脚本
# cd /scratch/hpc/07/zhang303/zsrobust/data/Imagenet
# python3 unzip.py

MASTER_PORT=$((10000 + RANDOM % 50000))

srun torchrun \
    --nproc_per_node=4 \
    --nnodes=$SLURM_NNODES \
    --node_rank=$SLURM_NODEID \
    --master_addr=$(scontrol show hostnames $SLURM_NODELIST | head -n 1) \
    --master_port=$MASTER_PORT \
    PMG_AFT.py \
    --batch_size 32 \
    --root ./data \
    --dataset tinyImageNet \
    --name wangsibo \
    --train_eps 1 \
    --train_numsteps 2 \
    --train_stepsize 1 \
    --epochs 10 \
    --add_prompt_size 0


# python PMG_AFT.py \
#    --batch_size 256 \
#    --root ./data \
#    --dataset tinyImageNet \
#    --name wangsibo \
#    --train_eps 1 \
#    --train_numsteps 2 \
#    --train_stepsize 1 \
#    --epochs 10 \
#    --add_prompt_size 0
