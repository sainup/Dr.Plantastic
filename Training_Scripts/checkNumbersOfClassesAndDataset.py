import os

DATASET_DIR = "F:/Anup/PJAIT/7th Semester/SUML/Materials/Project Dr. Plantastic/Dataset/PlantVillage"


def count_images_in_classes(dataset_dir):
    class_counts = {}
    

    for class_name in sorted(os.listdir(dataset_dir)):
        class_dir = os.path.join(dataset_dir, class_name)
        if not os.path.isdir(class_dir):
            continue  
        
      
        num_images = len([f for f in os.listdir(class_dir) if f.endswith(('.png', '.jpg', '.jpeg', '.JPG'))])
        class_counts[class_name] = num_images
    
    return class_counts


if __name__ == "__main__":
    class_counts = count_images_in_classes(DATASET_DIR)
    total_images = sum(class_counts.values())
    
    print("Number of images per class:")
    for class_name, count in class_counts.items():
        print(f"{class_name}: {count}")
    
    print(f"\nTotal number of images: {total_images}")
