from torchvision import datasets

# Path to your dataset directory
DATASET_DIR = "F:/Anup/PJAIT/7th Semester/SUML/Materials/Project Dr. Plantastic/Dataset/PlantVillage"

# Load dataset
dataset = datasets.ImageFolder(root=DATASET_DIR)

# Class-to-index mapping
class_to_idx = dataset.class_to_idx
print("Class-to-Index Mapping:")
print(class_to_idx)

# Index-to-Class mapping
idx_to_class = {v: k for k, v in class_to_idx.items()}
print("\nIndex-to-Class Mapping:")
print(idx_to_class)
