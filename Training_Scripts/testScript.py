import torch
from PIL import Image
from torchvision import transforms
from torchvision import datasets

DATASET_DIR = "F:/Anup/PJAIT/7th Semester/SUML/Materials/Project Dr. Plantastic/Dataset/PlantVillage"

# Load the TorchScript model
model = torch.jit.load("plant_disease_model_scripted.pt")
model.eval()

# Define image preprocessing
transform = transforms.Compose([
    transforms.Resize((256, 256)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
])


dataset = datasets.ImageFolder(root=DATASET_DIR)
idx_to_class = {v: k for k, v in dataset.class_to_idx.items()}

# Load an image for testing
img_path = "testTomato.jpeg"  
img = Image.open(img_path).convert("RGB")
img = transform(img).unsqueeze(0)  


with torch.no_grad():
    output = model(img)
    predicted_class_idx = output.argmax(dim=1).item()
    predicted_class_name = idx_to_class[predicted_class_idx]  
    print(f"Predicted Class: {predicted_class_name}")
