#!/bin/bash
#SBATCH --job-name=PMG_AFT
#SBATCH --output=logs/pmg_%j.out
#SBATCH --error=logs/pmg_%j.err
#SBATCH -p gpu-medium

#SBATCH --nodes=2                # 2 个节点
#SBATCH --gres=gpu:2             # 每节点 2 张 GPU，总共 4 张 GPU
#SBATCH --time=48:00:00
#SBATCH --mem=96G
#SBATCH --cpus-per-task=8

source ~/.bashrc
conda activate /storage/hpc/07/zhang303/conda_envs/zsrobust39

cd /scratch/hpc/07/zhang303/zsrobust

# NCCL 环境变量，避免多节点通信冲突
export NCCL_DEBUG=INFO
export NCCL_ASYNC_ERROR_HANDLING=1
export NCCL_IB_DISABLE=1

# 随机端口，避免冲突
MASTER_PORT=$((10000 + RANDOM % 50000))
MASTER_ADDR=$(scontrol show hostnames $SLURM_NODELIST | head -n 1)

# 每卡 batch=64，总 batch = 64 × 总卡数
PER_CARD_BATCH=64

srun torchrun \
    --nproc_per_node=2 \
    --nnodes=$SLURM_NNODES \
    --node_rank=$SLURM_NODEID \
    --master_addr=$MASTER_ADDR \
    --master_port=$MASTER_PORT \
    PMG_AFT.py \
    --batch_size $PER_CARD_BATCH \
    --root ./data \
    --dataset tinyImageNet \
    --name wangsibo \
    --train_eps 1 \
    --train_numsteps 2 \
    --train_stepsize 1 \
    --epochs 10 \
    --add_prompt_size 0
