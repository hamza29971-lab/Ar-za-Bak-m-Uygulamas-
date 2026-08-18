import os
from PIL import Image
from rembg import remove

images = [
    r"assets\images\loader.png",
    r"assets\images\euclid_truck.png",
    r"assets\images\green_truck.png"
]

for file in images:
    if os.path.exists(file):
        try:
            print(f"Processing {file}...")
            img = Image.open(file).convert("RGBA")
            
            # Resize image to max 800x800 to prevent OOM
            img.thumbnail((800, 800), Image.Resampling.LANCZOS)
            
            output_img = remove(img)
            output_img.save(file, "PNG")
            print(f"Success: {file}")
        except Exception as e:
            print(f"Failed {file}: {e}")
    else:
        print(f"File not found: {file}")
