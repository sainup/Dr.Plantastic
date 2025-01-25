import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _historyList = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  // Fetch prediction history from SQLite database
  Future<void> _fetchHistory() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String dbPath = "${directory.path}/plant_disease_history.db";

    final Database db = await openDatabase(dbPath);

    try {
      final List<Map<String, dynamic>> data = await db.query("History", orderBy: "timestamp DESC");
      setState(() {
        _historyList = data;
      });
    } catch (e) {
      print("Error fetching history: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Prediction History"),
      ),
      body: _historyList.isEmpty
          ? Center(child: Text("No history available.", style: TextStyle(fontSize: 18)))
          : ListView.builder(
              itemCount: _historyList.length,
              itemBuilder: (context, index) {
                final item = _historyList[index];
                return ListTile(
                  leading: item['imagePath'] != null
                      ? Image.file(File(item['imagePath']), width: 50, height: 50, fit: BoxFit.cover)
                      : Icon(Icons.image, size: 50),
                  title: Text(item['prediction'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item['timestamp']),
                );
              },
            ),
    );
  }
}
