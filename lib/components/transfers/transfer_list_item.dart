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
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            () => handleTransferTap(
              context: context,
              transfer: transfer,
              onUpdated: onUpdated,
              onDeleted: onDeleted,
            ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // icon transfer
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.swap_horiz, color: Colors.teal),
              ),
              const SizedBox(width: 12),
              // info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$fromWalletName → $toWalletName',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transfer.title.isNotEmpty ? transfer.title : 'Transfer',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // amount
              Text(
                CurrencyFormatter().encode(transfer.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                  fontSize: 16,
                ),
              ),
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
