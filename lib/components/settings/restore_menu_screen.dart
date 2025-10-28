// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../services/sqlite/backup_service.dart';
import '../../components/ui/alerts/flash_message.dart';

class RestoreMenuScreen extends StatelessWidget {
  const RestoreMenuScreen({super.key});

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
      appBar: AppBar(title: const Text('Restore Options')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open, color: Colors.teal),
            title: const Text('Restore from Local File'),
            subtitle: const Text('Select a backup file from your device'),
            onTap: () async {
              try {
                final success = await BackupService.restoreDatabaseWithPicker();
                _showSnack(
                  context,
                  success
                      ? 'Restore success! Restart app to apply.'
                      : 'Restore failed. Please select a valid backup file.',
                  success: success,
                );
              } catch (_) {
                _showSnack(context, 'Restore failed.', success: false);
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.cloud_download_outlined,
              color: Colors.indigoAccent,
            ),
            title: const Text('Restore from Google Drive'),
            subtitle: const Text('Download and restore backup from Drive'),
            onTap: () async {
              try {
                final success = await BackupService().restoreFromGoogleDrive();
                _showSnack(
                  context,
                  success
                      ? 'Restore from Google Drive complete!'
                      : 'No backup found or restore failed.',
                  success: success,
                );
              } catch (e) {
                _showSnack(context, 'Error: $e', success: false);
              }
            },
          ),
        ],
      ),
    );
  }
}
