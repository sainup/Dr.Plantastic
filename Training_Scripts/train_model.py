import os
import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import models, transforms, datasets
from sklearn.metrics import precision_score, recall_score, f1_score, confusion_matrix
from torchvision.datasets import DatasetFolder, ImageFolder
import matplotlib.pyplot as plt

# Define valid image extensions explicitly
VALID_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.JPG', '.JPEG', '.PNG'}

# Constants
IMG_SIZE = 256
BATCH_SIZE = 32
EPOCHS = 10
DATASET_DIR = "F:/Anup/PJAIT/7th Semester/SUML/Materials/Project Dr. Plantastic/Dataset/PlantVillage"
LOG_FILE = "training_results.txt"  # File to save metrics and results

# Custom ImageFolder class to include .JPG
class CustomImageFolder(ImageFolder):
    def __init__(self, root, transform=None, target_transform=None):
        super().__init__(root, transform=transform, target_transform=target_transform,
                         is_valid_file=self.is_valid_file)

    @staticmethod
    def is_valid_file(file_path):
        return os.path.splitext(file_path)[1] in VALID_EXTENSIONS


# Log all valid files for debugging
print("Logging all valid image files in dataset...")
for root, _, files in os.walk(DATASET_DIR):
    for file in files:
        if os.path.splitext(file)[1] in VALID_EXTENSIONS:
            print(f"Found valid file: {os.path.join(root, file)}")

# Check for GPU availability
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"Using device: {device}")

# Define dataset transformations
transform = transforms.Compose([
    transforms.Resize((IMG_SIZE, IMG_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])  # Normalize for ImageNet models
])

# Log class distribution
def log_class_distribution(dataset):
    class_counts = {class_name: 0 for class_name in dataset.classes}
    for _, label in dataset.samples:
        class_name = dataset.classes[label]
        class_counts[class_name] += 1

    print("Class distribution:")
    for class_name, count in class_counts.items():
        print(f"{class_name}: {count}")

    # Save the class distribution to the log file
    with open(LOG_FILE, "w") as f:
        f.write("Class distribution:\n")
        for class_name, count in class_counts.items():
            f.write(f"{class_name}: {count}\n")
        f.write("\n")  # Add a newline for better formatting

# Load dataset
print("Loading dataset...")
dataset = CustomImageFolder(root=DATASET_DIR, transform=transform)
log_class_distribution(dataset)  # Log the class distribution

train_size = int(0.8 * len(dataset))
val_size = len(dataset) - train_size
train_dataset, val_dataset = torch.utils.data.random_split(dataset, [train_size, val_size])

train_loader = torch.utils.data.DataLoader(train_dataset, batch_size=BATCH_SIZE, shuffle=True)
val_loader = torch.utils.data.DataLoader(val_dataset, batch_size=BATCH_SIZE, shuffle=False)

# Load pre-trained MobileNetV2
print("Loading pre-trained model...")
model = models.mobilenet_v2(pretrained=True)
model.classifier[1] = nn.Linear(model.last_channel, len(dataset.classes))  # Adjust output layer for the number of classes
model = model.to(device)

# Define loss function and optimizer
criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=0.001)

# Validation function
def validate_model(model, val_loader, criterion, device):
    model.eval()  # Set model to evaluation mode
    val_loss = 0.0
    correct = 0
    total = 0
    all_labels = []
    all_predictions = []

    with torch.no_grad():  # No gradients needed during validation
        for images, labels in val_loader:
            images, labels = images.to(device), labels.to(device)

            # Forward pass
            outputs = model(images)
            loss = criterion(outputs, labels)

            # Update metrics
            val_loss += loss.item()
            _, predicted = outputs.max(1)
            total += labels.size(0)
            correct += predicted.eq(labels).sum().item()

            # Collect predictions and true labels for metrics
            all_labels.extend(labels.cpu().numpy())
            all_predictions.extend(predicted.cpu().numpy())

    # Compute accuracy
    accuracy = 100. * correct / total
    avg_loss = val_loss / len(val_loader)

    # Calculate precision, recall, F1-score, and confusion matrix
    precision = precision_score(all_labels, all_predictions, average='weighted')
    recall = recall_score(all_labels, all_predictions, average='weighted')
    f1 = f1_score(all_labels, all_predictions, average='weighted')
    conf_matrix = confusion_matrix(all_labels, all_predictions)

    print("Confusion Matrix:")
    print(conf_matrix)

    return avg_loss, accuracy, precision, recall, f1

# Training loop with validation
train_results = []
val_results = []

print("Training model...")
for epoch in range(EPOCHS):
    # Training phase
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0

    for images, labels in train_loader:
        images, labels = images.to(device), labels.to(device)

        # Zero the parameter gradients
        optimizer.zero_grad()

        # Forward pass
        outputs = model(images)
        loss = criterion(outputs, labels)

        # Backward pass and optimize
        loss.backward()
        optimizer.step()

        # Update metrics
        running_loss += loss.item()
        _, predicted = outputs.max(1)
        total += labels.size(0)
        correct += predicted.eq(labels).sum().item()

    train_accuracy = 100. * correct / total
    train_loss = running_loss / len(train_loader)

    # Validation phase
    val_loss, val_accuracy, precision, recall, f1 = validate_model(model, val_loader, criterion, device)

    # Save results
    train_results.append((train_loss, train_accuracy))
    val_results.append((val_loss, val_accuracy))

    print(f"Epoch {epoch + 1}/{EPOCHS}, "
          f"Train Loss: {train_loss:.4f}, Train Accuracy: {train_accuracy:.2f}%, "
          f"Validation Loss: {val_loss:.4f}, Validation Accuracy: {val_accuracy:.2f}%, "
          f"Precision: {precision:.2f}, Recall: {recall:.2f}, F1-Score: {f1:.2f}")

    # Append results to the log file
    with open(LOG_FILE, "a") as f:
        f.write(f"Epoch {epoch + 1}/{EPOCHS}\n")
        f.write(f"Train Loss: {train_loss:.4f}, Train Accuracy: {train_accuracy:.2f}%\n")
        f.write(f"Validation Loss: {val_loss:.4f}, Validation Accuracy: {val_accuracy:.2f}%\n")
        f.write(f"Precision: {precision:.2f}, Recall: {recall:.2f}, F1-Score: {f1:.2f}\n")
        f.write("\n")

# Save the model
torch.save(model.state_dict(), "plant_disease_model.pth")
print("Model saved as plant_disease_model.pth")
