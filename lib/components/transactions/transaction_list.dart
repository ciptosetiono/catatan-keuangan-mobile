import 'package:flutter/material.dart';

import 'package:money_note/components/transactions/transaction_list_item.dart';
import 'package:money_note/models/transaction_model.dart';

class TransactionList extends StatelessWidget {
  final ScrollController? scrollController;
  final List<TransactionModel> transactions;
  final void Function(TransactionModel)? onItemUpdated;
  final VoidCallback? onItemDeleted;
  final bool isLoadingMore;

  const TransactionList({
    super.key,
    required this.transactions,
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
      itemCount: transactions.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i < transactions.length) {
          final transaction = transactions[i];
          return TransactionListItem(
            transaction: transaction,
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
