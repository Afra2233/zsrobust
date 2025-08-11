#!/bin/bash
#SBATCH --job-name=zsrobust_keepalive
#SBATCH --output=logs/keepalive_%j.out
#SBATCH --error=logs/keepalive_%j.err
#SBATCH -p cpu-short
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --requeue



# 刷新整个 zsrobust 目录的时间戳
find /scratch/hpc/07/zhang303/zsrobust -exec touch -m {} +


