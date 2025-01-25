import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'disease_detail_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _historyList = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  TextEditingController _searchController = TextEditingController();
  String _sortOrder = 'latest'; // Default sort order

  @override
  void initState() {
    super.initState();
    _requestStoragePermissions();
    _fetchHistory();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestStoragePermissions() async {
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }

    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
  }

  // Fetch prediction history from SQLite database
  Future<void> _fetchHistory() async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final String dbPath = "${directory.path}/plant_disease_history.db";
      final Database db = await openDatabase(dbPath);

      final List<Map<String, dynamic>> data =
          await db.query("History", orderBy: "timestamp DESC");
      setState(() {
        _historyList = data;
        _applyFilters();
      });
    } catch (e) {
      print("Error fetching history: $e");
      _showErrorSnackBar("Error fetching history. Please try again.");
    }
  }

  // Apply search and sort filters
  void _applyFilters() {
    setState(() {
      _filteredHistory = _historyList.where((record) {
        final query = _searchController.text.toLowerCase();
        return record['prediction'].toLowerCase().contains(query);
      }).toList();

      // Sort based on the selected sort order
      if (_sortOrder == 'latest') {
        _filteredHistory.sort((a, b) => DateTime.parse(b['timestamp'])
            .compareTo(DateTime.parse(a['timestamp'])));
      } else {
        _filteredHistory.sort((a, b) => DateTime.parse(a['timestamp'])
            .compareTo(DateTime.parse(b['timestamp'])));
      }
    });
  }

  // Delete a specific record from the database
  Future<void> _deleteRecord(int id) async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final String dbPath = "${directory.path}/plant_disease_history.db";
      print("Opening database in read-write mode...");
      final Database db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
            "CREATE TABLE History (id INTEGER PRIMARY KEY, imagePath TEXT, prediction TEXT, timestamp TEXT)",
          );
        },
        readOnly: false,
      );

      print("Database opened successfully. Attempting to delete...");
      await db.delete("History", where: "id = ?", whereArgs: [id]);
      setState(() {
        _historyList.removeWhere((item) => item['id'] == id);
        _applyFilters();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Record deleted successfully.")),
      );
    } catch (e) {
      print("Error deleting record: $e");
      _showErrorSnackBar("Error deleting record.");
    }
  }

  // Clear all history from the database
  Future<void> _clearHistory() async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final String dbPath = "${directory.path}/plant_disease_history.db";
      final Database db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
            "CREATE TABLE History (id INTEGER PRIMARY KEY, imagePath TEXT, prediction TEXT, timestamp TEXT)",
          );
        },
      );

      await db.delete("History");
      setState(() {
        _historyList.clear();
        _filteredHistory.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("All history cleared.")),
      );
    } catch (e) {
      print("Error clearing history: $e");
      _showErrorSnackBar("Error clearing history.");
    }
  }

  // Display error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Prediction History"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: () {
              // Show confirmation dialog for clearing history
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Clear History"),
                  content: Text("Are you sure you want to clear all history?"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearHistory();
                        Navigator.pop(context);
                      },
                      child: Text("Clear"),
                    ),
                  ],
                ),
              );
            },
          ),
          DropdownButton<String>(
            value: _sortOrder,
            icon: Icon(Icons.sort, color: Colors.white),
            dropdownColor: Colors.green,
            items: [
              DropdownMenuItem(value: 'latest', child: Text("Latest First")),
              DropdownMenuItem(value: 'oldest', child: Text("Oldest First")),
            ],
            onChanged: (value) {
              setState(() {
                _sortOrder = value!;
                _applyFilters();
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by disease...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: _filteredHistory.isEmpty
          ? Center(
              child: Text(
                "No history available.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _filteredHistory.length,
              itemBuilder: (context, index) {
                final item = _filteredHistory[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 10.0),
                  child: ListTile(
                    leading: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Colors.grey[200],
                      ),
                      child: item['imagePath'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.file(
                                File(item['imagePath']),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(Icons.image_not_supported,
                              size: 50, color: Colors.grey),
                    ),
                    title: Text(
                      item['prediction'],
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      item['timestamp'],
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // Show confirmation dialog for deleting a record
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Delete Record"),
                            content: Text(
                                "Are you sure you want to delete this record?"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () {
                                  _deleteRecord(item['id']);
                                  Navigator.pop(context);
                                },
                                child: Text("Delete"),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      // Navigate to the DiseaseDetailScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DiseaseDetailScreen(
                              diseaseKey: item['prediction']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
