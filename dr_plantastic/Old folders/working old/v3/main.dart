import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'history_screen.dart';
import 'disease_detail_screen.dart';
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

  Future<void> _loadModel() async {
    try {
      _model = await PytorchLite.loadClassificationModel(
        "assets/plant_disease_model_scripted.pt",
        256,
        256,
        15,
        labelPath: "assets/labels.json",
      );
    } catch (e) {
      print("Error loading classification model: $e");
    }
  }

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

  Future<void> _predictImage(File image) async {
    try {
      String rawPrediction = await _model.getImagePrediction(await image.readAsBytes());
      String predictionLabel = rawPrediction.split(": ").last.replaceAll('"', '');

      setState(() {
        _prediction = predictionLabel;
      });

      _savePrediction(image.path, _prediction!);
    } catch (e) {
      print("Prediction error: $e");
    }
  }

  Future<void> _savePrediction(String imagePath, String prediction) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String dbPath = "${directory.path}/plant_disease_history.db";
    final Database db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) {
        db.execute(
          "CREATE TABLE History (id INTEGER PRIMARY KEY, imagePath TEXT, prediction TEXT, timestamp TEXT)",
        );
      },
    );

    await db.insert("History", {
      "imagePath": imagePath,
      "prediction": prediction,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }

  String _generateGoogleSearchURL(String query) => "https://www.google.com/search?q=$query";

  Future<void> _launchURL(String query) async {
    final Uri url = Uri.parse(_generateGoogleSearchURL(query));
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedImage != null)
              Image.file(
                _selectedImage!,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              )
            else
              Column(
                children: [
                  Icon(Icons.image, size: 100, color: Colors.grey),
                  Text("No image selected", style: TextStyle(fontSize: 18)),
                ],
              ),
            SizedBox(height: 20),
            if (_prediction != null)
              Column(
                children: [
                  Text("Prediction: $_prediction", style: TextStyle(fontSize: 18)),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DiseaseDetailScreen(diseaseKey: _prediction!)),
                      );
                    },
                    child: Text("View Details"),
                  ),
                  TextButton(
                    onPressed: () => _launchURL(_prediction!),
                    child: Text("Search on Google"),
                  ),
                ],
              )
            else
              Text("Prediction will appear here."),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Select Image"),
            ),
          ],
        ),
      ),
    );
  }
}
