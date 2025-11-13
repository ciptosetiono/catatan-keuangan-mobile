// ignore_for_file: avoid_print

import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

class GoogleDriveService {
  final _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope, // akses Drive user
    ],
  );

  /// 🔑 Sign in & return authorized Drive API
  Future<drive.DriveApi?> signInAndGetDriveApi() async {
    try {
      final account =
          await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
      if (account == null) {
        print('❌ User cancelled Google sign-in');
        return null;
      }

      final authHeaders = await account.authHeaders;
      final client = _GoogleAuthClient(authHeaders);
      return drive.DriveApi(client);
    } catch (e) {
      print('❌ Google Drive sign-in failed: $e');
      return null;
    }
  }

  /// 📁 Get or create "Moneyger Backups" folder
  Future<String> _getOrCreateBackupFolder(drive.DriveApi api) async {
    const folderName = 'Moneyger Backups';

    final existing = await api.files.list(
      q: "name='$folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
    );

    if (existing.files?.isNotEmpty ?? false) {
      return existing.files!.first.id!;
    }

    final folder =
        drive.File()
          ..name = folderName
          ..mimeType = 'application/vnd.google-apps.folder';

    final created = await api.files.create(folder);
    print('📂 Folder created: ${created.name}');
    return created.id!;
  }

  /// ☁️ Upload file ke folder "Moneyger Backups"
  Future<void> uploadBackup(File backupFile) async {
    final api = await signInAndGetDriveApi();
    if (api == null) throw Exception('Google Drive API not available');

    final folderId = await _getOrCreateBackupFolder(api);
    final fileName = backupFile.uri.pathSegments.last;

    // Hapus file lama dengan nama yang sama
    final existing = await api.files.list(
      q: "name='$fileName' and '$folderId' in parents and trashed=false",
    );
    if (existing.files?.isNotEmpty ?? false) {
      await api.files.delete(existing.files!.first.id!);
      print('🗑️ Old backup deleted: $fileName');
    }

    final driveFile =
        drive.File()
          ..name = fileName
          ..parents = [folderId]
          ..mimeType = 'application/octet-stream';

    try {
      final result = await api.files.create(
        driveFile,
        uploadMedia: drive.Media(
          backupFile.openRead(),
          backupFile.lengthSync(),
        ),
      );
      print('✅ Backup uploaded successfully: ${result.id}');
    } catch (e) {
      print('❌ Upload failed: $e');
      rethrow;
    }
  }

  /// 🔄 Download latest backup dari folder "Moneyger Backups"
  Future<File?> downloadLatestBackup() async {
    final api = await signInAndGetDriveApi();
    if (api == null) throw Exception('Google Drive not connected');

    try {
      final folderId = await _getOrCreateBackupFolder(api);

      final fileList = await api.files.list(
        q: "'$folderId' in parents and trashed=false",
        orderBy: 'modifiedTime desc',
        $fields: 'files(id, name, modifiedTime)',
      );

      final files = fileList.files;
      if (files == null || files.isEmpty) {
        print('⚠️ No backup files found in folder "$folderId"');
        return null;
      }

      final latestFile = files.first;

      final response = await api.files.get(
        latestFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      if (response is! drive.Media) {
        throw Exception('Unexpected response type from Drive API');
      }

      final dir = await Directory.systemTemp.createTemp('moneyger_restore_');
      final localFile = File('${dir.path}/${latestFile.name}');
      final outputStream = localFile.openWrite();
      await response.stream.pipe(outputStream);
      await outputStream.close();

      print('✅ Backup downloaded: ${localFile.path}');
      return localFile;
    } catch (e, st) {
      print('❌ Error downloading backup: $e\n$st');
      return null;
    }
  }

  /// 🚪 Sign out dari Google Drive
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    print('👋 Signed out from Google Drive');
  }
}

/// Authenticated HTTP client helper
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() => _client.close();
}
