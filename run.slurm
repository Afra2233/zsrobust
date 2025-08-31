#!/bin/bash
#SBATCH --job-name=PMG_AFT
#SBATCH --output=logs/pmg_%j.out
#SBATCH --error=logs/pmg_%j.err
#SBATCH -p gpu-medium
#SBATCH --nodes=1
#SBATCH --gres=gpu:2
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
# export TORCH_DISTRIBUTED_DEBUG=DETAIL
# export NCCL_DEBUG=INFO

python PMG_AFT.py \
   --batch_size 256 \
   --root ./data \
   --dataset tinyImageNet \
   --name wangsibo \
   --train_eps 1 \
   --train_numsteps 10 \
   --train_stepsize 1 \
   --epochs 10 \
   --add_prompt_size 0 \
   --trial 8

#   --resume "./save/models/wangsibo_null_patch_30_tinyImageNet_clip_vit_b32_lr_5e-05_decay_0_bsz_256_warmup_1000_trial_8_addp_0_template_this_is_a_photo_of_a_{}/model_best.pth.tar" \
#   --evaluate \