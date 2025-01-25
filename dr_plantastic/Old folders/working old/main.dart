import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:typed_data';
import 'history_screen.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dr. Plantastic',
      theme: ThemeData(primarySwatch: Colors.green),
      home: PlantDiseaseHome(),
    );
  }
}

class PlantDiseaseHome extends StatefulWidget {
  const PlantDiseaseHome({super.key});

  @override
  _PlantDiseaseHomeState createState() => _PlantDiseaseHomeState();
}

class _PlantDiseaseHomeState extends State<PlantDiseaseHome> {
  File? _selectedImage;
  String? _prediction;
  late ClassificationModel _model;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  // Load the classification model
  Future<void> _loadModel() async {
    try {
      print("Attempting to load the model...");
      _model = await PytorchLite.loadClassificationModel(
        "assets/plant_disease_model_scripted.pt", // Path to the model file
        256, // Input width
        256, // Input height
        15, // Number of classes
        labelPath: "assets/labels.json", // Path to the labels
      );
      print("Model loaded successfully!");
    } catch (e) {
      print("Error loading classification model: $e");
    }
  }

  // Pick an image from the gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });

      _predictImage(File(image.path));
    }
  }

  // Predict the selected image
  // Predict the selected image
Future<void> _predictImage(File image) async {
  try {
    Uint8List imageBytes = await image.readAsBytes();
    String rawPrediction = await _model.getImagePrediction(imageBytes);

    // Extract only the label part from the prediction
    String predictionLabel = rawPrediction.split(": ").last.replaceAll('"', '');

    setState(() {
      _prediction = predictionLabel; // Use only the label part
    });

    _savePrediction(image.path, _prediction!);
  } catch (e) {
    print("Error during prediction: $e");
  }
}


  // Save prediction to SQLite database
  Future<void> _savePrediction(String imagePath, String prediction) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String dbPath = "${directory.path}/plant_disease_history.db";

    // Open database
    final Database db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          "CREATE TABLE History (id INTEGER PRIMARY KEY, imagePath TEXT, prediction TEXT, timestamp TEXT)",
        );
      },
    );

    // Insert prediction
    await db.insert("History", {
      "imagePath": imagePath,
      "prediction": prediction,
      "timestamp": DateTime.now().toIso8601String(),
    });

    print("Prediction saved to history.");
  }

  // Generate Google search URL dynamically
  String _generateGoogleSearchURL(String disease) {
    return "https://www.google.com/search?q=$disease";
  }

  // Launch URL
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not launch $url";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dr. Plantastic"),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_selectedImage != null)
            Image.file(_selectedImage!)
          else
            Text(
              "No image selected",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          SizedBox(height: 20),
          if (_prediction != null)
            Column(
              children: [
                Text(
                  "Prediction: $_prediction",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () => _launchURL(_generateGoogleSearchURL(_prediction!)),
                  child: Text("Search on Google", style: TextStyle(fontSize: 16, color: Colors.blue)),
                ),
              ],
            )
          else
            Text(
              "Prediction will appear here.",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text("Select Image"),
          ),
        ],
      ),
    );
  }
}
