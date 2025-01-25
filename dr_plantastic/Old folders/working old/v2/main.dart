import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:typed_data';
import 'history_screen.dart';
import 'disease_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';


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

  Map<String, String> _labelMap = {};

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadLabels();
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

  // Load labels from JSON
  Future<void> _loadLabels() async {
    try {
      String jsonString = await DefaultAssetBundle.of(context).loadString('assets/labels.json');
      Map<String, dynamic> labels = Map<String, dynamic>.from(await Future.value(json.decode(jsonString)));
      setState(() {
        _labelMap = labels.map((key, value) => MapEntry(key, value.toString()));
      });
      print("Labels loaded: $_labelMap");
    } catch (e) {
      print("Error loading labels: $e");
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
  Future<void> _predictImage(File image) async {
    try {
      Uint8List imageBytes = await image.readAsBytes();
      String rawPrediction = await _model.getImagePrediction(imageBytes);

      // Extract prediction and map it to the label
      String predictionIndex = rawPrediction.split(":").first.replaceAll(RegExp(r'[^0-9]'), '');
      String? predictionLabel = _labelMap[predictionIndex];

      setState(() {
        _prediction = predictionLabel; // Use the mapped label
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
  String _generateGoogleSearchURL(String query) {
    return "https://www.google.com/search?q=$query";
  }

  // Launch URL
  Future<void> _launchURL(String query) async {
    final Uri url = Uri.parse(_generateGoogleSearchURL(query));
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
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
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DiseaseDetailScreen(diseaseKey: _prediction!),
                      ),
                    );
                  },
                  child: Text("View Details"),
                ),
                TextButton(
                  onPressed: () => _launchURL(_prediction!),
                  child: Text(
                    "Search on Google",
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
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
