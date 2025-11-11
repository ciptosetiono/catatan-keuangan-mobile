// ignore_for_file: avoid_print

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../google_drive_service.dart';
import 'db_helper.dart';
import '../../config/database_config.dart';

class BackupService {
  /// 📦 Backup DB ke folder Downloads (Android) atau Documents (iOS)
  static Future<File?> backupDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final dbFile = File(join(dbPath, dbConfig['name']));

      if (!await dbFile.exists()) {
        throw Exception("Database file not found");
      }

      Directory targetDir;

      if (Platform.isAndroid) {
        // ⚠️ Hanya bekerja jika user beri izin akses Storage
        targetDir = Directory('/storage/emulated/0/Download');
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File(
        join(targetDir.path, 'moneyger_backup_$timestamp.db'),
      );

      await dbFile.copy(backupFile.path);

      print('✅ Local backup created at: ${backupFile.path}');
      return backupFile;
    } catch (e, st) {
      print('❌ Backup failed: $e\n$st');
      return null;
    }
  }

  /// 📂 Restore DB dari file picker (user memilih file .db)
  static Future<bool> restoreDatabaseWithPicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) {
        print('⚠️ Restore cancelled or invalid file.');
        return false;
      }

      final backupFile = File(result.files.single.path!);
      final dbPath = await getDatabasesPath();
      final dbFile = File(join(dbPath, dbConfig['name']));

      await DBHelper.close();
      await backupFile.copy(dbFile.path);
      await DBHelper.reopen();

      print('✅ Database restored successfully from file picker');
      return true;
    } catch (e, st) {
      print('❌ Restore failed: $e\n$st');
      return false;
    }
  }

  /// ☁️ Backup ke Google Drive (ke folder "Moneyger Backups")
  Future<void> backupToGoogleDrive() async {
    try {
      final localBackupFile = await backupDatabase();
      if (localBackupFile == null) throw Exception('Local backup failed');

      final driveService = GoogleDriveService();
      await driveService.uploadBackup(localBackupFile);

      print('✅ Backup uploaded to Google Drive successfully');
    } catch (e, st) {
      print('❌ Google Drive backup failed: $e\n$st');
    }
  }

  /// 🔄 Restore DB dari Google Drive (ambil file terbaru)
  Future<bool> restoreFromGoogleDrive() async {
    try {
      final driveService = GoogleDriveService();
      final backupFile = await driveService.downloadLatestBackup();

      if (backupFile == null) {
        print('⚠️ No backup file found on Google Drive');
        return false;
      }

      final dbPath = await getDatabasesPath();
      final dbFile = File(join(dbPath, dbConfig['name']));

      await DBHelper.close();
      await backupFile.copy(dbFile.path);
      await DBHelper.reopen();

      print('✅ Database restored successfully from Google Drive');
      return true;
    } catch (e, st) {
      print('❌ Restore failed: $e\n$st');
      return false;
    }
  }
}
