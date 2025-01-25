# Dr. Plantastic 🌱

Dr. Plantastic is a **Flutter-based mobile application** designed to help farmers and agricultural experts detect plant diseases from leaf images. The app uses a **CNN-based MobileNetV2 model** for disease prediction, displaying both the detected disease and a confidence score. Additional features include a searchable and sortable prediction history and detailed disease information.

## 📖 Features
- **Plant Disease Detection**: Upload a leaf image, and the app predicts the disease using a trained CNN model.
- **Confidence Score**: Each prediction is accompanied by a confidence percentage to indicate model certainty.
- **Prediction History**: View a searchable and sortable log of previous predictions.
- **Disease Details**: Access detailed information about plant diseases, including possible causes and remedies.
- **User-Friendly Interface**: Simple and intuitive design to ensure ease of use.

## 🛠️ Technology Stack
- **Frontend**: Flutter (Dart)
- **Backend**: SQLite (local storage for prediction history)
- **Machine Learning Model**: MobileNetV2 (trained with PyTorch)
- **Dataset**: PlantVillage dataset (preprocessed for training)

## 🚀 How to Run the Project
### Prerequisites
1. [Flutter SDK](https://flutter.dev/docs/get-started/install)
2. A device or emulator configured for Flutter development
3. Python (for training the model, optional)
4. Clone this repository:
   ```bash
   git clone https://github.com/<your-username>/Dr.Plantastic.git
   cd Dr.Plantastic

## Running the App
1. Navigate to the Flutter directory:
   ```bash
   cd dr_plantastic
2. Get Flutter dependencies:
    ```bash
   flutter pub get
3. Connect a physical device or start an emulator.
4. Run the app:
   ```bash
   flutter run

## Training the Model (Optional)
1. Navigate to the Training_Scripts directory:
   ```bash
   cd Training_Scripts
2. Preprocess the dataset using data_preprocessing.py.
3. Train the model using train_model.py.
4. Replace the existing model in dr_plantastic/assets with the newly trained model.

## 📊 Results and Metrics
- **Accuracy**: 98.16%
- **Precision**: 98.00%
- **Recall**: 98.00%
- **F1-Score**: 98.00%
  
Training logs and confusion matrices are available in the repository under the Training_Scripts directory.

## 📂 Repository Structure
  ```plaintext
├── Model/                       # Pre-trained MobileNetV2 model
├── Project_Proposal_documentation/ # Project initial document
├── Training_Scripts/            # Scripts for data preprocessing and model training
├── dr_plantastic/               # Flutter application source code
│   ├── assets/                  # Model and label files
│   ├── lib/                     # Flutter app code
│   └── pubspec.yaml             # Flutter dependencies
```
## ✨ Future Enhancements
- Improve the dataset by adding more diverse images and underrepresented classes.
- Integrate cloud-based storage for prediction history and model updates.
- Add real-time disease detection using the device camera.
