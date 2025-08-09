import 'dart:io';

import 'package:data_keeper/database/database_helper.dart';
import 'package:data_keeper/models/user_model.dart';
import 'package:data_keeper/screens/db_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class ImportDbScreen extends StatefulWidget {
  const ImportDbScreen({super.key});

  @override
  State<ImportDbScreen> createState() => _ImportDbScreenState();
}

class _ImportDbScreenState extends State<ImportDbScreen> {
  bool _isLoading = false;
  String? _message;
  bool _overwrite = false;

  Future<void> _pickAndImportDb() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        await _importUsersFromDb(result.files.single.path!);
      } else {
        setState(() {
          _message = "No file selected";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importUsersFromDb(String path) async {
    if (_overwrite) {
      await DatabaseHelper.instance.replaceDatabase(path);
      setState(() {
        _message = 'Database replaced successfully!';
      });
    } else {
      final tempDb = await openDatabase(path);
      final tableExists = await _checkTableSchema(tempDb);

      if (!tableExists) {
        setState(() {
          _message = 'Invalid DB: Required table/columns not found.';
        });
        await tempDb.close();
        return;
      }

      final List<Map<String, Object?>> maps = await tempDb.query('users');
      for (var map in maps) {
        final name = map['name']?.toString() ?? '';
        final phone = map['phone']?.toString() ?? '';
        final city = map['city']?.toString() ?? '';
        final postalCode = map['postalCode']?.toString() ?? '';
        final street = map['street']?.toString() ?? '';

        if (name.isNotEmpty && phone.isNotEmpty) {
          await DatabaseHelper.instance.insertUser(
            User(
              name: name,
              phone: phone,
              city: city,
              postalCode: postalCode,
              street: street,
            ),
          );
        }
      }

      await tempDb.close();
      setState(() {
        _message = 'Users imported successfully!';
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DbViewerScreen(dbPath: path),
      ),
    );
  }

  Future<bool> _checkTableSchema(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(users);");
      final columns = result.map((row) => row['name']).toList();
      return columns.contains('name') &&
          columns.contains('phone') &&
          columns.contains('city') &&
          columns.contains('postalCode') &&
          columns.contains('street');
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Database',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Sen')),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.upload_file,
                        size: 64,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Import Database File',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Select a .db file to import users data',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _pickAndImportDb,
                        icon: const Icon(Icons.upload_file),
                        label: const Text(
                          'Select DB File',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _overwrite,
                            onChanged: (bool? value) {
                              setState(() {
                                _overwrite = value ?? false;
                              });
                            },
                            fillColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                              if (states.contains(MaterialState.selected)) {
                                return Colors.blue;
                              }
                              return Colors.white;
                            }),
                          ),
                          const Text(
                            'Overwrite existing database',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_isLoading)
                        const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text(
                              'Importing...',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      if (_message != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _message!.startsWith("✅")
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _message!.startsWith("✅")
                                  ? Colors.green.shade200
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Text(
                            _message!,
                            style: TextStyle(
                              color: _message!.startsWith("✅")
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
