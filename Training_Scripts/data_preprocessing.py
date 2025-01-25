import os
import cv2
import numpy as np

# Constants
DATASET_DIR = "F:/Anup/PJAIT/7th Semester/SUML/Materials/Project Dr. Plantastic/Dataset/PlantVillage"
BATCH_SIZE = 32  # Number of images to load at a time
VALID_EXTENSIONS = [".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG"]  # Include all extensions

def log_dataset_stats(dataset_dir):
    """Logs the total number of images per class."""
    class_names = sorted(os.listdir(dataset_dir))
    total_images = 0
    print("Class-wise image count:")
    for class_name in class_names:
        class_dir = os.path.join(dataset_dir, class_name)
        if not os.path.isdir(class_dir):
            continue
        count = len([img for img in os.listdir(class_dir) if os.path.splitext(img)[1] in VALID_EXTENSIONS])
        print(f"{class_name}: {count}")
        total_images += count
    print(f"Total images: {total_images}\n")
    return total_images  # Return total images for verification

# Generator for loading data in batches
def image_data_generator(dataset_dir, batch_size=BATCH_SIZE):
    """Yields batches of images and labels."""
    class_names = sorted(os.listdir(dataset_dir))  # Ensure consistent class order
    image_paths = []
    labels = []

    # Collect image paths and corresponding labels
    for label, class_name in enumerate(class_names):
        class_dir = os.path.join(dataset_dir, class_name)
        if not os.path.isdir(class_dir):
            continue
        for img_name in os.listdir(class_dir):
            if os.path.splitext(img_name)[1] in VALID_EXTENSIONS:  # Filter valid extensions
                image_paths.append(os.path.join(class_dir, img_name))
                labels.append(label)

    # Shuffle the data
    image_paths = np.array(image_paths)
    labels = np.array(labels)
    indices = np.arange(len(image_paths))
    np.random.shuffle(indices)
    image_paths = image_paths[indices]
    labels = labels[indices]

    # Yield batches of images and labels
    for start in range(0, len(image_paths), batch_size):
        end = min(start + batch_size, len(image_paths))
        batch_paths = image_paths[start:end]
        batch_labels = labels[start:end]
        images = [cv2.imread(path) for path in batch_paths]
        images = np.array(images) / 255.0  # Normalize to 0-1
        yield np.array(images), np.array(batch_labels), class_names

# Example usage
if __name__ == "__main__":
    print("Logging dataset stats...")
    total_images = log_dataset_stats(DATASET_DIR)
    print("Loading dataset in batches...")
    
    generator = image_data_generator(DATASET_DIR)
    total_processed = 0

    for X_batch, y_batch, class_names in generator:
        print(f"Processed batch of {len(X_batch)} images.")
        total_processed += len(X_batch)

    print(f"Total images processed: {total_processed}")
    print(f"Class names: {class_names}")

    # Ensure that all images were processed
    assert total_processed == total_images, "Not all images were processed!"
