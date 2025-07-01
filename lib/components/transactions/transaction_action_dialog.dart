import 'package:flutter/material.dart';

Future<String?> showTransactionActionDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder:
        (ctx) => SimpleDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'detail'),
              child: const Text('Detail'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'edit'),
              child: const Text('Edit'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: const Text('Delete'),
            ),
          ],
        ),
  );
}
