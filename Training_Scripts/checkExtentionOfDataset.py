import os

DATASET_DIR = "F:/Anup/PJAIT/7th Semester/SUML/Materials/Project Dr. Plantastic/Dataset/PlantVillage"

extensions = set()

for root, _, files in os.walk(DATASET_DIR):
    for file in files:
        extensions.add(os.path.splitext(file)[1])

print("File extensions found:", extensions)
