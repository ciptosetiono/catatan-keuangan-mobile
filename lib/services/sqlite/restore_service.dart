import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../config/database_config.dart';

Future<void> restoreDatabase() async {
  // Let user pick backup file
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['db'], // only allow database files
  );

  if (result != null && result.files.single.path != null) {
    final backupFile = File(result.files.single.path!);

    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, dbConfig['name']);

    await backupFile.copy(dbPath);
  } else {}
}
