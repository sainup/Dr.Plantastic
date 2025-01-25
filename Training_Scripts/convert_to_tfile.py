import torch
from torchvision import models

# Load the trained model
model_path = "plant_disease_model.pth"
model = models.mobilenet_v2(pretrained=False)
model.classifier[1] = torch.nn.Linear(model.last_channel, 15)  # Adjust for 15 classes (update based on your dataset)
model.load_state_dict(torch.load(model_path))
model.eval()

# Convert to TorchScript
example_input = torch.rand(1, 3, 256, 256)  # Example input tensor
traced_model = torch.jit.trace(model, example_input)

# Save the TorchScript model
traced_model_path = "plant_disease_model_scripted.pt"
traced_model.save(traced_model_path)
print(f"Model converted and saved to {traced_model_path}")
