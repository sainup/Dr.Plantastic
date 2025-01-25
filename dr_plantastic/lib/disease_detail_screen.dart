import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';

class DiseaseDetailScreen extends StatelessWidget {
  final String diseaseKey;

  DiseaseDetailScreen({required this.diseaseKey});

  Future<Map<String, dynamic>> _loadDiseaseData() async {
    final String response = await rootBundle.loadString('assets/disease_info.json');
    return json.decode(response);
  }

  String _generateGoogleSearchURL(String query) {
    return "https://www.google.com/search?q=$query";
  }

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
      appBar: AppBar(title: Text("Disease Details")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadDiseaseData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading disease details."));
          } else if (!snapshot.data!.containsKey(diseaseKey)) {
            return Center(child: Text("No details available for this disease."));
          }

          final disease = snapshot.data![diseaseKey];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disease['name'],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text("Symptoms:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(disease['symptoms']),
                TextButton(
                  onPressed: () => _launchURL("Symptoms for ${disease['name']}"),
                  child: Text("More about Symptoms", style: TextStyle(color: Colors.blue)),
                ),
                SizedBox(height: 20),
                Text("Treatment:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(disease['treatment']),
                TextButton(
                  onPressed: () => _launchURL("Treatment for ${disease['name']}"),
                  child: Text("More about Treatment", style: TextStyle(color: Colors.blue)),
                ),
                SizedBox(height: 20),
                Text("Prevention:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(disease['prevention']),
                TextButton(
                  onPressed: () => _launchURL("Prevention for ${disease['name']}"),
                  child: Text("More about Prevention", style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
