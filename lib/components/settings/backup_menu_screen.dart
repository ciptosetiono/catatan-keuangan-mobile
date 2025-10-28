// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../services/sqlite/backup_service.dart';
import '../../components/ui/alerts/flash_message.dart';

class BackupMenuScreen extends StatelessWidget {
  const BackupMenuScreen({super.key});

  void _showSnack(BuildContext context, String message, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      FlashMessage(
        color: success ? Colors.green : Colors.red,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup Options')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.folder_copy, color: Colors.purple),
            title: const Text('Backup to Local File'),
            subtitle: const Text('Save your data to device storage'),
            onTap: () async {
              try {
                final file = await BackupService.backupDatabase();
                _showSnack(
                  context,
                  file != null
                      ? 'Backup success! Saved to Downloads directory.'
                      : 'Backup failed. Please try again.',
                  success: file != null,
                );
              } catch (_) {
                _showSnack(context, 'Backup failed.', success: false);
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.cloud_upload_outlined,
              color: Colors.indigo,
            ),
            title: const Text('Backup to Google Drive'),
            subtitle: const Text('Upload your backup file to Google Drive'),
            onTap: () async {
              try {
                await BackupService().backupToGoogleDrive();
                _showSnack(context, 'Backup to Google Drive successful!');
              } catch (_) {
                _showSnack(
                  context,
                  'Backup to Google Drive failed.',
                  success: false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
