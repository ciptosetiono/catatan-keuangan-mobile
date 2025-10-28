import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../google_drive_service.dart';
import 'db_helper.dart';
import '../../config/database_config.dart';

class BackupService {
  /// Backup DB ke Downloads/Documents
  static Future<File?> backupDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final dbFile = File(join(dbPath, dbConfig['name']));

      if (!await dbFile.exists()) {
        throw Exception("Database file not found");
      }

      // Get Downloads folder
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory(
          '/storage/emulated/0/Download',
        ); // Android Downloads
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory(); // iOS fallback
      } else {
        downloadsDir =
            await getApplicationDocumentsDirectory(); // fallback lain
      }

      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File(
        join(downloadsDir.path, 'moneyger_backup_$timestamp.db'),
      );

      await dbFile.copy(backupFile.path);

      return backupFile;
    } catch (e) {
      return null;
    }
  }

  /// Restore DB dari file picker
  static Future<bool> restoreDatabaseWithPicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result == null ||
          result.files.isEmpty ||
          result.files.single.path == null) {
        return false;
      }

      final backupFilePath = result.files.single.path!;

      final backupFile = File(backupFilePath);

      final dbPath = await getDatabasesPath();
      final dbFile = File(join(dbPath, dbConfig['name']));

      await DBHelper.close();

      await backupFile.copy(dbFile.path);

      await DBHelper.reopen();

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> backupToGoogleDrive() async {
    final localBackupFile = await backupDatabase();
    if (localBackupFile == null) return;

    final driveService = GoogleDriveService();
    final api =
        await driveService
            .signInAndGetDriveApi(); // will trigger Google login popup

    if (api == null) {
      throw Exception('Google sign-in failed');
    }

    await driveService.uploadBackup(localBackupFile);
  }

  /// Restore DB dari Google Drive (file terbaru)
  Future<bool> restoreFromGoogleDrive() async {
    try {
      final driveService = GoogleDriveService();
      final backupFile = await driveService.downloadLatestBackup();

      if (backupFile == null) {
        // ignore: avoid_print
        print('No backup file found on Drive');
        return false;
      }

      // Path database lokal
      final dbPath = await getDatabasesPath();
      final dbFile = File(join(dbPath, dbConfig['name']));

      await DBHelper.close();

      // Replace existing DB with downloaded backup
      await backupFile.copy(dbFile.path);

      await DBHelper.reopen();

      // ignore: avoid_print
      print('Database restored successfully from Google Drive');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Restore failed: $e');
      return false;
    }
  }
}
