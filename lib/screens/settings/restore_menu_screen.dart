// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../services/sqlite/backup_service.dart';
import '../../components/ui/alerts/flash_message.dart';

class RestoreMenuScreen extends StatefulWidget {
  const RestoreMenuScreen({super.key});

  @override
  State<RestoreMenuScreen> createState() => _RestoreMenuScreenState();
}

class _RestoreMenuScreenState extends State<RestoreMenuScreen> {
  bool _isLoading = false;

  void _showSnack(String message, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      FlashMessage(
        color: success ? Colors.green : Colors.red,
        message: message,
      ),
    );
  }

  Future<void> _handleRestore(
    Future<bool> Function() action,
    String successMsg,
    String failMsg,
  ) async {
    setState(() => _isLoading = true);
    try {
      final success = await action();
      _showSnack(success ? successMsg : failMsg, success: success);
    } catch (e) {
      _showSnack('Error: $e', success: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Restore Options')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.folder_open, color: Colors.teal),
                title: const Text('Restore from Local File'),
                subtitle: const Text('Select a backup file from your device'),
                onTap:
                    () => _handleRestore(
                      BackupService.restoreDatabaseWithPicker,
                      'Restore success! Restart app to apply.',
                      'Restore failed. Please select a valid backup file.',
                    ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.cloud_download_outlined,
                  color: Colors.indigoAccent,
                ),
                title: const Text('Restore from Google Drive'),
                subtitle: const Text('Download and restore backup from Drive'),
                onTap:
                    () => _handleRestore(
                      () => BackupService().restoreFromGoogleDrive(),
                      'Restore from Google Drive complete!',
                      'No backup found or restore failed.',
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
