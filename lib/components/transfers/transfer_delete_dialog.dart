// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:money_note/services/transfer_service.dart';

Future<bool> showTransferDeleteDialog({
  required BuildContext context,
  required String transferId,
  VoidCallback? onDeleted,
}) async {
  final transferService = TransferService();
  bool isLoading = false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Delete Transfer'),
            content:
                isLoading
                    ? const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    )
                    : const Text(
                      'Are you sure you want to delete this Transaction ?',
                    ),

            actions:
                isLoading
                    ? []
                    : [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() => isLoading = true);
                          try {
                            await transferService.deleteTransfer(transferId);

                            if (onDeleted != null) onDeleted();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Transaction deleted succesfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          } catch (e) {
                            setState(() => isLoading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
          );
        },
      );
    },
  );
  return result ?? false;
}
