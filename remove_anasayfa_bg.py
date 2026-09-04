import os
from PIL import Image

file = r"assets\images\anasayfa\EuclidAnasayfa.png"
if os.path.exists(file):
    try:
        print(f"Processing {file}...")
        img = Image.open(file).convert("RGBA")
        data = img.getdata()
        
        new_data = []
        for item in data:
            if item[0] > 240 and item[1] > 240 and item[2] > 240:
                new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)
                
        img.putdata(new_data)
        img.save(file, "PNG")
        print(f"Success: {file}")
    except Exception as e:
        print(f"Failed {file}: {e}")
else:
    print("File not found.")
