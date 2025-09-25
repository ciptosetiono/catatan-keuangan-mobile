import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../config/database_config.dart';

Future<void> backupDatabase() async {
  // Get current database
  final databasesPath = await getDatabasesPath();
  final dbPath = join(databasesPath, dbConfig['name']);
  final dbFile = File(dbPath);

  // Let user pick a folder (Android only, iOS will pick file)
  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

  if (selectedDirectory != null) {
    final backupPath = join(selectedDirectory, dbConfig['name']);
    await dbFile.copy(backupPath);
  } else {}
}
