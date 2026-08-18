from PIL import Image
import os

def remove_white_bg(image_path):
    if not os.path.exists(image_path):
        print(f"Not found: {image_path}")
        return
    try:
        print(f"Processing {image_path}...")
        img = Image.open(image_path).convert("RGBA")
        data = img.getdata()
        
        new_data = []
        for item in data:
            # Beyaz veya beyaza çok yakın pikselleri (rgb > 240) şeffaf yap
            if item[0] > 240 and item[1] > 240 and item[2] > 240:
                new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)
                
        img.putdata(new_data)
        img.save(image_path, "PNG")
        print(f"Success: {image_path}")
    except Exception as e:
        print(f"Failed {image_path}: {e}")

images = [
    "assets/images/loader.png",
    "assets/images/euclid_truck.png",
    "assets/images/green_truck.png",
    "assets/images/xcmg_truck.png"
]

for img in images:
    remove_white_bg(img)
