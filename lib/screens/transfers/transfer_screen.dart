import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/date_filter_option.dart';

import '../../../components/alerts/flash_message.dart';
import '../../components/transactions/wallet_filter_dropdown.dart';
import '../../components/transactions/date_filter_dropdown.dart';
import '../../components/transfers/transfer_action_dialog.dart';
import '../../components/transfers/transfer_delete_dialog.dart';

import '../../../models/transaction_model.dart';
import '../../../models/wallet_model.dart';
import '../../../services/transfer_service.dart';
import '../../../services/wallet_service.dart';

import '../../screens/transfers/transfer_form_screen.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final TransferService _transferService = TransferService();
  final WalletService _walletService = WalletService();

  List<Wallet> _wallets = [];
  DateTime? _fromDate;
  DateTime? _toDate;

  String? _fromWalletId;
  String? _toWalletId;

  // ignore: unused_field
  String _dateFilterLabel = 'This Month';
  DateFilterOption _selectedDateFilter = DateFilterOption.thisMonth;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final walletsStream = _walletService.getWalletStream();
    final wallets = await walletsStream.first;
    setState(() {
      _wallets = wallets;
    });
  }

  String _getWalletName(String id) {
    return _wallets
        .firstWhere(
          (w) => w.id == id,
          orElse:
              () => Wallet(
                id: id,
                name: 'Tidak diketahui',
                userId: '-',
                startBalance: 0,
                currentBalance: 0,
                createdAt: DateTime.now(),
              ),
        )
        .name;
  }

  Future<void> _confirmDelete(BuildContext context, TransactionModel tx) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: 'Hapus Transfer',
      message: 'Apakah kamu yakin ingin menghapus transfer ini?',
    );
    if (confirm == true) {
      await _transferService.deleteTransfer(tx.id);
      ScaffoldMessenger.of(context).showSnackBar(
        FlashMessage(
          color: Colors.green,
          message: 'Transaction updated successfully',
        ),
      );
    }
  }

  Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
  }

  void _applyDateFilter(
    DateFilterOption option, {
    DateTime? from,
    DateTime? to,
    String? label,
  }) {
    setState(() {
      _selectedDateFilter = option;
      _fromDate = from;
      _toDate = to;
      _dateFilterLabel = label ?? 'This Month';
    });
  }

  Future<void> _handleTransferTap(
    BuildContext context,
    TransactionModel transfer,
  ) async {
    final selected = await showTransferActionDialog(context);
    if (selected == 'edit') {
      await Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (_) => TransferFormScreen(transfer: transfer),
        ),
      );
    } else if (selected == 'delete') {
      // ignore: use_build_context_synchronously
      final confirm = await showTransferDeleteDialog(context);
      if (confirm) {
        await TransferService().deleteTransfer(transfer.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: WalletFilterDropdown(
                    value: _fromWalletId,
                    placeholder: 'From Wallet',
                    onChanged: (val) {
                      setState(() => _fromWalletId = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: WalletFilterDropdown(
                    placeholder: 'To Wallet',
                    value: _toWalletId,
                    onChanged: (val) {
                      setState(() => _toWalletId = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DateFilterDropdown(
                    selected: _selectedDateFilter,
                    onFilterApplied: _applyDateFilter,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _transferService.getTransfers(
          fromWalletId: _fromWalletId,
          toWalletId: _toWalletId,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Terjadi kesalahan saat memuat data.'),
            );
          }

          final transfers = snapshot.data ?? [];

          if (transfers.isEmpty) {
            return const Center(child: Text('Belum ada transfer.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const Divider(height: 20),
            itemCount: transfers.length,
            itemBuilder: (context, index) {
              final tx = transfers[index];
              return ListTile(
                onTap: () => _handleTransferTap(context, tx),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(
                  _getWalletName(tx.fromWalletId!) +
                      ' → ' +
                      _getWalletName(tx.toWalletId!),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(tx.title),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                      ).format(tx.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    Text(DateFormat('dd/MM yyyy').format(tx.date)),
                  ],
                ),
                onLongPress: () => _confirmDelete(context, tx),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransferFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
