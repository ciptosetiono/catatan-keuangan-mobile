import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

class GoogleDriveService {
  final _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope, // permission for app's own Drive files
    ],
  );

  /// Sign in and return an authorized Drive API instance
  Future<drive.DriveApi?> signInAndGetDriveApi() async {
    try {
      final account =
          await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
      if (account == null) {
        // ignore: avoid_print
        print('User cancelled Google sign-in');
        return null;
      }

      final authHeaders = await account.authHeaders;
      final client = _GoogleAuthClient(authHeaders);
      return drive.DriveApi(client);
    } catch (e) {
      // ignore: avoid_print
      print('Google Drive sign-in failed: $e');
      return null;
    }
  }

  /// Upload file to Google Drive (App folder)
  Future<void> uploadBackup(File backupFile) async {
    final api = await signInAndGetDriveApi();
    if (api == null) throw Exception('Google Drive API not available');

    final fileName = backupFile.uri.pathSegments.last;

    // Remove existing file if same name exists
    final existing = await api.files.list(
      spaces: 'appDataFolder',
      q: "name='$fileName'",
    );
    if (existing.files?.isNotEmpty ?? false) {
      await api.files.delete(existing.files!.first.id!);
    }

    final driveFile =
        drive.File()
          ..name = fileName
          ..parents = ['appDataFolder'];

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

  /// Download and restore the latest backup from Google Drive
  Future<File?> downloadLatestBackup() async {
    final api = await signInAndGetDriveApi();
    if (api == null) throw Exception('Google Drive not connected');

    try {
      // Get files sorted by modifiedTime desc (newest first)
      final fileList = await api.files.list(
        spaces: 'appDataFolder',
        orderBy: 'modifiedTime desc',
        $fields: 'files(id, name, modifiedTime)',
      );

      final files = fileList.files;
      if (files == null || files.isEmpty) {
        print('⚠️ No backup files found on Google Drive');
        return null;
      }

      final latestFile = files.first;
      print('⬇️ Downloading backup: ${latestFile.name}');

      // Download file content
      final response = await api.files.get(
        latestFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      if (response is! drive.Media) {
        throw Exception('Unexpected response type from Drive API');
      }

      // Save to temporary local file
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
