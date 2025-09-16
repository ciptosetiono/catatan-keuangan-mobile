// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency_formatter.dart';
import 'package:money_note/components/transfers/transfer_delete_dialog.dart';
import 'package:money_note/components/transfers/transfer_action_dialog.dart';
import 'package:money_note/screens/transfers/transfer_form_screen.dart';

class TransferListItem extends StatelessWidget {
  final TransactionModel transfer;
  final String Function(String? walletId) getWalletName;
  final VoidCallback? onUpdated;
  final VoidCallback? onDeleted;

  const TransferListItem({
    super.key,
    required this.transfer,
    required this.getWalletName,
    this.onUpdated,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(transfer.date);
    final fromWalletName = getWalletName(transfer.fromWalletId);
    final toWalletName = getWalletName(transfer.toWalletId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap:
            () => handleTransferTap(
              context: context,
              transfer: transfer,
              onUpdated: onUpdated,
              onDeleted: onDeleted,
            ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            '$fromWalletName → $toWalletName',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(transfer.title),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter().encode(transfer.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              Text(dateStr),
            ],
          ),
        ),
      ),
    );
  }
}

/// A reusable handler for transfer actions (detail, edit, delete).
Future<void> handleTransferTap({
  required BuildContext context,
  required TransactionModel transfer,
  Function()? onUpdated,
  Function()? onDeleted,
}) async {
  final action = await showTransferActionDialog(context);

  if (action == 'edit') {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TransferFormScreen(transfer: transfer)),
    );

    if (result == 'updated' && onUpdated != null) {
      onUpdated();
    } else if (result == 'deleted' && onDeleted != null) {
      onDeleted();
    }
  } else if (action == 'delete') {
    final deleted = await showTransferDeleteDialog(
      context: context,
      transferId: transfer.id,
    );

    if (deleted == true && onDeleted != null) {
      onDeleted();
    }
  }
}
