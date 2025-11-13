// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../services/sqlite/backup_service.dart';
import '../../components/ui/alerts/flash_message.dart';

class BackupMenuScreen extends StatefulWidget {
  const BackupMenuScreen({super.key});

  @override
  State<BackupMenuScreen> createState() => _BackupMenuScreenState();
}

class _BackupMenuScreenState extends State<BackupMenuScreen> {
  bool _isLoading = false;

  void _showSnack(String message, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      FlashMessage(
        color: success ? Colors.green : Colors.red,
        message: message,
      ),
    );
  }

  Future<void> _handleBackup(
    Future<void> Function() action,
    String successMsg,
    String failMsg,
  ) async {
    setState(() => _isLoading = true);
    try {
      await action();
      _showSnack(successMsg);
    } catch (e) {
      _showSnack('$failMsg\n$e', success: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLocalBackup() async {
    setState(() => _isLoading = true);
    try {
      final file = await BackupService.backupDatabase();
      _showSnack(
        file != null
            ? 'Backup success! Saved to Downloads directory.'
            : 'Backup failed. Please try again.',
        success: file != null,
      );
    } catch (e) {
      _showSnack('Backup failed: $e', success: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Backup Options')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.folder_copy, color: Colors.purple),
                title: const Text('Backup to Local File'),
                subtitle: const Text('Save your data to device storage'),
                onTap: _handleLocalBackup,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.indigo,
                ),
                title: const Text('Backup to Google Drive'),
                subtitle: const Text('Upload your backup file to Google Drive'),
                onTap:
                    () => _handleBackup(
                      () => BackupService().backupToGoogleDrive(),
                      'Backup to Google Drive successful!',
                      'Backup to Google Drive failed.',
                    ),
              ),
            ],
          ),
        ),

        // 🌀 Overlay loading indicator
        if (_isLoading)
          Container(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.4),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
