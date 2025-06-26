import 'package:flutter/material.dart';

Future<String?> showTransactionActionDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder:
        (ctx) => SimpleDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Opsi Transaksi'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'edit'),
              child: const Text('Edit'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: const Text('Hapus'),
            ),
            const Divider(),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
  );
}
