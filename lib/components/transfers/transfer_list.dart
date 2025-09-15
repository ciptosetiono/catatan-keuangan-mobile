import 'package:flutter/material.dart';

import 'package:money_note/components/transfers/transfer_list_item.dart';
import 'package:money_note/models/transaction_model.dart';

class TransferList extends StatelessWidget {
  final ScrollController? scrollController;
  final List<TransactionModel> transfers;
  final String Function(String? walletId) getWalletName;
  final VoidCallback? onItemUpdated;
  final VoidCallback? onItemDeleted;
  final bool isLoadingMore;

  const TransferList({
    super.key,
    required this.transfers,
    required this.getWalletName,
    this.scrollController,
    this.onItemUpdated,
    this.onItemDeleted,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: transfers.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i < transfers.length) {
          final transfer = transfers[i];
          return TransferListItem(
            transfer: transfer,
            getWalletName: getWalletName,
            onUpdated: onItemUpdated,
            onDeleted: onItemDeleted,
          );
        } else {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
