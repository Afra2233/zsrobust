#!/bin/bash
#SBATCH --job-name=tinyimage_download
#SBATCH -p parallel
#SBATCH --nodes=1
#SBATCH --time=48:00:00
#SBATCH --mem=96G
#SBATCH --cpus-per-task=8

srun /storage/hpc/07/zhang303/conda_envs/zsrobust39/bin/python dataset_downlaod.py