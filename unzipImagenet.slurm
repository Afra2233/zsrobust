#!/bin/bash
#SBATCH --job-name=unzip_Image
#SBATCH -p parallel              
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=96G
#SBATCH --chdir=/scratch/hpc/07/zhang303/zsrobust
#SBATCH --output=logs/unzip_Image_%j.out
#SBATCH --error=logs/unzip_Image_%j.err

# cd data/Imagenet
# mkdir train && tar -xvf ILSVRC2012_img_train.tar -C train && for x in `ls train/*tar`; do fn=train/`basename $x .tar`; mkdir $fn; tar -xvf $x -C $fn; rm -f $fn.tar; done

cd data/Imagenet

# 改名：train → train_1
mkdir train_1
tar -xvf ILSVRC2012_img_train.tar -C train_1

# 循环解压每个类别的 tar 包
for x in train_1/*.tar; do
    fn="train_1/$(basename "$x" .tar)"
    mkdir "$fn"
    tar -xvf "$x" -C "$fn"
    rm -f "$x"
done
