// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:money_note/services/budget_service.dart';

Future<bool> showBudgetDeleteDialog({
  required BuildContext context,
  required String budgetId,
  VoidCallback? onDeleted,
}) async {
  final budgetService = BudgetService();
  bool isLoading = false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Delete Budget'),
            content:
                isLoading
                    ? const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    )
                    : const Text(
                      'Are you sure you want to delete this Budget ?',
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
                            await budgetService.deleteBudget(budgetId);
                            Navigator.pop(ctx, true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Budget deleted succesfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
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
  if (deleted && onDeleted != null) {
    onDeleted(); // hanya refresh list, jangan panggil dialog lagi
  }
  return deleted;
}
