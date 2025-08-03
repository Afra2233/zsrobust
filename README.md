### Replace
Replace the files in the replace folder to the source code in your environmet:  

replace `anaconda3/envs/zsrobust/lib/python3.9/site-packages/clip/clip.py` and `anaconda3/envs/zsrobust/lib/python3.9/site-packages/clip/model.py` with clip.py and model.py in the replace folder respectively. 

replace the `anaconda3/envs/zsrobust/lib/python3.9/site-packages/torchvision/datasets` with the files in `replace/torchvision.datasets` 
for updated dataset loader

### Run
python PMG_AFT.py --batch_size 256 --root ./data --dataset tinyImageNet --name wangsibo --train_eps 1 --train_numsteps 2 --train_stepsize 1
