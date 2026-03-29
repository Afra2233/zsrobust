#!/bin/bash
#SBATCH --job-name=tinyimage_download
#SBATCH -p parallel
#SBATCH --nodes=1
#SBATCH --time=48:00:00
#SBATCH --mem=96G
#SBATCH --cpus-per-task=8


srun python download_tiny_imagenet.py