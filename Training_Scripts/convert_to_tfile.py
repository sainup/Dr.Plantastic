import torch
from torchvision import models

model_path = "plant_disease_model.pth"
model = models.mobilenet_v2(pretrained=False)
model.classifier[1] = torch.nn.Linear(model.last_channel, 15) 
model.load_state_dict(torch.load(model_path))
model.eval()

example_input = torch.rand(1, 3, 256, 256) 
traced_model = torch.jit.trace(model, example_input)

traced_model_path = "plant_disease_model_scripted.pt"
traced_model.save(traced_model_path)
print(f"Model converted and saved to {traced_model_path}")
