#!/bin/bash
#SBATCH --job-name=unzip_Image
#SBATCH -p parallel              
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=96G
#SBATCH --chdir=/scratch/hpc/07/zhang303/zsrobust
#SBATCH --output=logs/unzip_Image_%j.out
#SBATCH --error=logs/unzip_Image_%j.err

cd data/Imagenet
mkdir train && tar -xvf ILSVRC2012_img_train.tar -C train && for x in `ls train/*tar`; do fn=train/`basename $x .tar`; mkdir $fn; tar -xvf $x -C $fn; rm -f $fn.tar; done

