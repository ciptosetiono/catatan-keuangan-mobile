import 'package:flutter/material.dart';

import 'package:money_note/components/transactions/transaction_delete_dialog.dart';
import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/screens/transactions/transaction_form_screen.dart';

Future<void> showTransactionBottomsheetMenu({
  required BuildContext context,
  required TransactionModel transaction,
}) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.green),
              title: const Text('Edit'),
              onTap: () async {
                Navigator.pop(context); // tutup bottomsheet
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => TransactionFormScreen(
                          transactionId: transaction.id,
                          existingData: transaction,
                          onSaved: () {
                            Navigator.pop(context, true); // reload list
                          },
                        ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(context); // tutup bottomsheet
                final deleted = await showTransactionDeleteDialog(
                  context: context,
                  transactionId: transaction.id,
                );
                if (deleted == true && context.mounted) {
                  Navigator.pop(
                    context,
                    true,
                  ); // balik ke screen sebelumnya & reload
                }
              },
            ),
          ],
        ),
      );
    },
  );
}
