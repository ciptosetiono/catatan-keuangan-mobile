import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency_formatter.dart';

class TransferListItem extends StatelessWidget {
  final TransactionModel transfer;
  final String Function(String? walletId) getWalletName;
  final VoidCallback? onTap;

  const TransferListItem({
    super.key,
    required this.transfer,
    required this.getWalletName,
    this.onTap,
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
        onTap: onTap,
        child: ListTile(
          contentPadding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 10,
            bottom: 10,
          ),
          title: Text('$fromWalletName → $toWalletName'),
          subtitle: Text(dateStr, style: const TextStyle(height: 1.4)),
          trailing: Text(
            CurrencyFormatter().encode(transfer.amount),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
