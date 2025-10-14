import 'package:flutter/material.dart';
import 'dart:async';
import 'package:money_note/utils/currency_formatter.dart';
import 'package:money_note/constants/date_filter_option.dart';

import 'package:money_note/components/forms/date_filter_dropdown.dart';
import 'package:money_note/components/transactions/transaction_list.dart';
import 'package:money_note/components/transactions/transaction_summary_card.dart';
import 'package:money_note/components/transfers/transfer_list.dart';
import 'package:money_note/components/wallets/wallet_delete_dialog.dart';
import 'package:money_note/components/wallets/wallet_info_card.dart';

import 'package:money_note/models/wallet_model.dart';
import 'package:money_note/models/transaction_model.dart';

import 'package:money_note/services/sqlite/transaction_service.dart';
import 'package:money_note/services/sqlite/transfer_service.dart';
import 'package:money_note/services/sqlite/wallet_service.dart';

import 'package:money_note/screens/wallets/wallet_form_screen.dart';

class WalletDetailScreen extends StatefulWidget {
  final Wallet wallet;

  const WalletDetailScreen({super.key, required this.wallet});

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen>
    with SingleTickerProviderStateMixin {
  final TransactionService _transactionService = TransactionService();
  final TransferService _transferService = TransferService();
  final WalletService _walletService = WalletService();
  final currencyFormatter = CurrencyFormatter();

  Wallet? _wallet;
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _transfers = [];
  List<Wallet> _wallets = [];
  StreamSubscription? _walletSub;

  late TabController _tabController;

  bool _loadingTransactions = true;
  bool _loadingTransfers = true;

  DateTime? _from;
  DateTime? _to;
  DateFilterOption _selectedDateFilter = DateFilterOption.all;
  @override
  void initState() {
    super.initState();
    _wallet = widget.wallet;
    _tabController = TabController(length: 2, vsync: this);

    // listen perubahan wallet real-time
    _listenWallet();
    _loadWallets();
    _loadTransactions();
    _loadTransfers();
  }

  @override
  void dispose() {
    _walletSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _listenWallet() {
    _walletSub = _walletService.getWalletStreamById(widget.wallet.id).listen((
      wallet,
    ) {
      if (!mounted) return;
      setState(() {
        _wallet = wallet;
      });
    });
  }

  Future<void> _loadWallets() async {
    final wallets = await _walletService.getWalletStream().first;
    if (!mounted) return;
    setState(() {
      _wallets = wallets;
    });
  }

  void _loadTransactions() {
    _loadingTransactions = true;

    final from =
        _from ??
        (_selectedDateFilter != DateFilterOption.all
            ? _from
            : null); // opsional: default semua
    final to =
        _to ?? (_selectedDateFilter != DateFilterOption.all ? _to : null);

    _transactionService
        .getTransactionsStream(
          walletId: widget.wallet.id,
          type: null, // ambil semua tipe
          fromDate: from,
          toDate: to,
        )
        .listen((data) {
          if (!mounted) return;
          setState(() {
            _transactions = data;
            _loadingTransactions = false;
          });
        });
  }

  void _loadTransfers() {
    _transferService
        .getTransfersByWallet(widget.wallet.id)
        .listen(
          (data) {
            if (!mounted) return;
            setState(() {
              _transfers = data;
              _loadingTransfers = false;
            });
          },
          onError: (e) {
            debugPrint("Error loading transfers: $e");
            if (!mounted) return;
            setState(() {
              _loadingTransfers = false;
            });
          },
        );
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
    String? label,
    DateTime? to,
  }) {
    setState(() {
      _selectedDateFilter = option;
      _from = from;
      _to = to;
    });
  }

  Widget _buildTransactionsTab() {
    if (_loadingTransactions) {
      return const Center(child: CircularProgressIndicator());
    }

    // filter tanggal
    final filteredTransactions =
        _transactions.where((tx) {
          if (_from != null && tx.date.isBefore(_from!)) return false;
          if (_to != null && tx.date.isAfter(_to!)) return false;
          return true;
        }).toList();

    if (filteredTransactions.isEmpty) {
      return const Center(child: Text("No transactions found"));
    }

    final income = filteredTransactions
        .where((tx) => tx.type == "income")
        .fold<int>(0, (sum, tx) => sum + tx.amount.toInt());
    final expense = filteredTransactions
        .where((tx) => tx.type == "expense")
        .fold<int>(0, (sum, tx) => sum + tx.amount.toInt());

    final balance = income - expense;
    return Column(
      children: [
        TransactionSummaryCard(
          income: income,
          expense: expense,
          balance: balance,
        ),
        Expanded(
          child: TransactionList(
            transactions: filteredTransactions,
            onItemUpdated: (updatedTransaction) {
              //_loadWallet();
            },
            // onItemDeleted: _loadWallet,
          ),
        ),
      ],
    );
  }

  Widget _buildTransfersTab() {
    if (_loadingTransfers) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredTransfers =
        _transfers.where((t) {
          if (_from != null && t.date.isBefore(_from!)) return false;
          if (_to != null && t.date.isAfter(_to!)) return false;
          return true;
        }).toList();

    if (filteredTransfers.isEmpty) {
      return const Center(child: Text("No transfers found"));
    }

    final totalOut = filteredTransfers
        .where((t) => t.fromWalletId == widget.wallet.id)
        .fold<int>(0, (sum, t) => sum + t.amount.toInt());
    final totalIn = filteredTransfers
        .where((t) => t.toWalletId == widget.wallet.id)
        .fold<int>(0, (sum, t) => sum + t.amount.toInt());
    final transactionBalance = totalIn - totalOut;
    return Column(
      children: [
        TransactionSummaryCard(
          income: totalIn,
          expense: totalOut,
          balance: transactionBalance,
        ),
        Expanded(
          child: TransferList(
            transfers: filteredTransfers,
            getWalletName: _getWalletName,
            // onItemUpdated: _loadWallet, //refresh wallet data
            // onItemDeleted: _loadWallet, //refresh wallet data
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 150,
              child: DateFilterDropdown(
                selected: _selectedDateFilter,
                //label: _selectedDateLabel,
                onFilterApplied: _applyDateFilter,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
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
                  final updatedWallet = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WalletFormScreen(wallet: _wallet),
                    ),
                  );

                  if (updatedWallet != null && mounted) {
                    setState(() {
                      _wallet = updatedWallet as Wallet?;
                    });

                    // opsional: reload transaksi dan transfer
                    _loadTransactions();
                    _loadTransfers();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () async {
                  Navigator.pop(context); // tutup bottomsheet
                  final deleted = await showWalletDeleteDialog(
                    context: context,
                    walletId: widget.wallet.id,
                  );
                  if (deleted == true && context.mounted) {
                    Navigator.pop(context, true); // balik ke list & reload
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet Detail")),
      body: Column(
        children: [
          WalletInfoCard(wallet: _wallet!),
          _buildFilterRow(),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [Tab(text: "Transactions"), Tab(text: "Transfers")],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildTransactionsTab(), _buildTransfersTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.more_vert),
        onPressed: () => _showActions(context),
      ),
    );
  }
}
