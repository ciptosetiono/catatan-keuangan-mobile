// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:money_note/services/transaction_service.dart';
import 'package:money_note/models/transaction_model.dart';

Future<bool> showTransactionDeleteDialog({
  required BuildContext context,
  required TransactionModel transaction,
  VoidCallback? onDeleted,
}) async {
  final transactionService = TransactionService();

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      bool isLoading = false;

      return StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> deleteTransaction() async {
            setState(() => isLoading = true);

            try {
              await transactionService.deleteTransaction(transaction);

              if (onDeleted != null) onDeleted();

              // Tampilkan SnackBar sebelum menutup dialog
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted successfully!'),
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
                    content: Text('Failed to delete: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }

          return AlertDialog(
            title: const Text('Delete Transaction'),
            content:
                isLoading
                    ? const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    )
                    : const Text(
                      'Are you sure you want to delete this transaction?',
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
                        onPressed: deleteTransaction,
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

  debugPrint("deleted result from dialog: $result");

  return result ?? false;
}
