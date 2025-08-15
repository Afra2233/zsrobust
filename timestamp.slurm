#!/bin/bash
#SBATCH --job-name=zsrobust_keepalive
#SBATCH --output=logs/keepalive_%j.out
#SBATCH --error=logs/keepalive_%j.err
#SBATCH -p parallel
#SBATCH --time=10:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=10G
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --requeue



# 刷新整个 zsrobust 目录的时间戳
# find /scratch/hpc/07/zhang303/zsrobust -exec touch -m {} +

# find /scratch/hpc/07/zhang303/zsrobust -type f -exec touch {} +

find /scratch/hpc/07/zhang303/zsrobust -exec touch {} +