from torchvision.datasets import Places365

root = "/scratch/hpc/07/zhang303/data/places365"

splits = ["train-standard", "val", "test"]

for split in splits:
    print(f"\n[INFO] downloading split={split}")
    ds = Places365(
        root=root,
        split=split,
        small=True,      # 256x256
        download=True,
    )
    print(f"[INFO] finished split={split}, size={len(ds)}")