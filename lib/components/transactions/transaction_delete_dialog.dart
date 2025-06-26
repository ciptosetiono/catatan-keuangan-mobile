import 'package:flutter/material.dart';

Future<bool> showTransactionDeleteDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Hapus Transaksi'),
          content: const Text('Yakin ingin menghapus transaksi ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
  );
  return result ?? false;
}
