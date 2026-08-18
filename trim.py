from PIL import Image
import glob

def trim_images():
    images = glob.glob("assets/images/*.png")
    for path in images:
        try:
            img = Image.open(path)
            # getbbox() works on the alpha channel to find the non-zero bounding box
            bbox = img.getbbox()
            if bbox:
                img_cropped = img.crop(bbox)
                img_cropped.save(path)
                print(f"Cropped {path} to {bbox}")
            else:
                print(f"No bounding box found for {path}")
        except Exception as e:
            print(f"Failed processing {path}: {e}")

if __name__ == "__main__":
    trim_images()
