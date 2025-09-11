// lib/utils/dialog_utils.dart

import 'package:flutter/material.dart';
import 'package:money_note/services/category_service.dart';

Future<bool> confirmAndDeleteCategory({
  required BuildContext context,
  required String categoryId,
  VoidCallback? onDeleted,
}) async {
  final categoryService = CategoryService();
  bool isLoading = false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Delete Category'),
            content:
                isLoading
                    ? const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    )
                    : const Text(
                      'Are you sure you want to delete this category?',
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
                            await categoryService.deleteCategory(categoryId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Category deleted succesfully!'),
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
