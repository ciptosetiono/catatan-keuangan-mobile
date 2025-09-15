import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:money_note/constants/date_filter_option.dart';
import 'package:money_note/utils/currency_formatter.dart';

import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/models/wallet_model.dart';

import 'package:money_note/services/transfer_service.dart';
import 'package:money_note/services/wallet_service.dart';

import 'package:money_note/components/alerts/flash_message.dart';
import 'package:money_note/components/transactions/wallet_filter_dropdown.dart';
import 'package:money_note/components/transactions/date_filter_dropdown.dart';

import 'package:money_note/components/transfers/transfer_list.dart';
import 'package:money_note/components/transfers/transfer_action_dialog.dart';
import 'package:money_note/components/transfers/transfer_delete_dialog.dart';

import 'package:money_note/screens/transfers/transfer_form_screen.dart';

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
    if (!mounted) return;
    setState(() {
      _wallets = wallets;
    });
  }

  String _getWalletName(String? id) {
    if (id == null) return 'unknown';
    return _wallets
        .firstWhere(
          (w) => w.id == id,
          orElse:
              () => Wallet(
                id: id,
                name: 'unknown',
                userId: '-',
                startBalance: 0,
                currentBalance: 0,
                createdAt: DateTime.now(),
              ),
        )
        .name;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfers'),
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
            return const Center(child: Text('Failed to load transfers data'));
          }

          final transfers = snapshot.data ?? [];

          if (transfers.isEmpty) {
            return const Center(child: Text('There are no transfers yet.'));
          }

          return TransferList(
            transfers: transfers,
            getWalletName: _getWalletName,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransferFormScreen()),
          ).then((_) {
            // Refresh the transfers list after adding a new transfer
            setState(() {});
          });
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
