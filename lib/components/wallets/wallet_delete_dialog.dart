import 'package:flutter/material.dart';
import 'package:money_note/services/wallet_service.dart';

Future<bool> showWalletDeleteDialog({
  required BuildContext context,
  required String walletId,
  VoidCallback? onDeleted,
}) async {
  final walletService = WalletService();
  bool isLoading = false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Delete Wallet'),
            content:
                isLoading
                    ? const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    )
                    : const Text(
                      'Are you sure you want to delete this Wallet ?',
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
                            await walletService.deleteWallet(walletId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Wallet deleted succesfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(ctx, true);
                          } catch (e) {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
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
  final deleted = result ?? false;
  if (deleted) {
    if (onDeleted != null) onDeleted();
  }
  return deleted;
}
