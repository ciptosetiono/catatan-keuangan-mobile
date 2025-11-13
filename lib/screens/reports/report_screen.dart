import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_note/constants/date_filter_option.dart';
import 'package:money_note/components/reports/report_chart.dart';
import 'package:money_note/components/reports/report_filter.dart';
import 'package:money_note/components/transactions/transaction_summary_card.dart';
import 'package:money_note/components/reports/report_list.dart';
import 'package:money_note/components/ads/banner_ad_widget.dart';
import 'package:money_note/services/sqlite/transaction_service.dart';
import 'package:money_note/services/sqlite/wallet_service.dart';
import 'package:money_note/services/sqlite/category_service.dart';
import 'package:money_note/services/export_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateFilterOption? selectedRange;
  DateTime? fromDate;
  DateTime? toDate;
  String? selectedLabel;
  String groupBy = "day";

  final TransactionService _transactionService = TransactionService();
  List<Map<String, dynamic>> transactions = [];

  final CategoryService _categoryService = CategoryService();
  Map<String, String> categoryMap = {};

  final WalletService _walletService = WalletService();
  Map<String, String> walletMap = {};

  double income = 0;
  double expense = 0;
  double balance = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadMasterData();
    await _loadTransactions();
  }

  Future<void> _loadMasterData() async {
    final catList = await _categoryService.getCategories();
    final walletList = await _walletService.getWallets();

    setState(() {
      categoryMap = {for (var cat in catList) cat.id: cat.name};
      walletMap = {for (var wallet in walletList) wallet.id: wallet.name};
    });
  }

  Future<void> _loadTransactions() async {
    _transactionService
        .getTransactionsStream(fromDate: fromDate, toDate: toDate)
        .listen((txList) {
          if (!mounted) return;
          setState(() {
            transactions =
                txList.map((tx) {
                  final txMap = tx.toMap();
                  return txMap;
                }).toList();
            _calculateSummary();
          });
        });
  }

  void _calculateSummary() {
    income = 0;
    expense = 0;
    for (var tx in transactions) {
      if (tx["type"] == "income") {
        income += (tx["amount"] as num).toDouble();
      } else {
        expense += (tx["amount"] as num).toDouble();
      }
    }
    balance = income - expense;
  }

  Map<String, List<Map<String, dynamic>>> _groupTransactions() {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var tx in transactions) {
      final rawDate = tx["date"];
      DateTime date;

      if (rawDate is DateTime) {
        date = rawDate;
      } else if (rawDate is String) {
        date = DateTime.tryParse(rawDate) ?? DateTime.now();
      } else if (rawDate is int) {
        // assume it's a timestamp in milliseconds
        date = DateTime.fromMillisecondsSinceEpoch(rawDate);
      } else {
        // ignore: avoid_print
        print(
          "⚠️ Unknown date type in transaction: $rawDate (${rawDate.runtimeType})",
        );
        continue; // skip this transaction instead of throwing
      }

      String key;
      switch (groupBy) {
        case "day":
          key = DateFormat("dd MMM yyyy").format(date);
          break;
        case "week":
          final weekOfYear = ((date.dayOfYear - date.weekday + 10) / 7).floor();
          key = "Week $weekOfYear, ${date.year}";
          break;
        case "month":
          key = DateFormat("MMM yyyy").format(date);
          break;
        case "year":
          key = date.year.toString();
          break;
        default:
          key = DateFormat("dd MMM yyyy").format(date);
      }

      if (tx["amount"] is String) {
        tx["amount"] = double.tryParse(tx["amount"]) ?? 0.0;
      }

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(tx);
    }
    return grouped;
  }

  void _applyDateFilter(
    DateFilterOption option, {
    DateTime? from,
    DateTime? to,
    String? label,
  }) {
    if (!mounted) return;
    setState(() {
      selectedRange = option;
      selectedLabel = label;
      fromDate = from;
      toDate = to;
    });
    _loadTransactions();
  }

  void _export(String type) async {
    final exportService = ReportExportService();
    if (type == "csv") exportService.exportToCsv(transactions: transactions);
    if (type == "pdf") exportService.exportToPdf(transactions: transactions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Page"),
        bottom: ReportFilter(
          groupBy: groupBy,
          selectedRange: DateFilterOption.thisMonth,
          onDateRangePicked: _applyDateFilter,
          onGroupChanged: (group) {
            if (!mounted) return;
            setState(() {
              groupBy = group;
            });
          },
        ),
      ),
      body: Column(
        children: [
          TransactionSummaryCard(
            income: income,
            expense: expense,
            balance: balance,
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ReportChart(
                groupedData: _groupTransactions(),
                groupBy: groupBy,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: ReportList(
              groupedData: _groupTransactions(),
              groupBy: groupBy,
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            _export(value);
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
              ],
        ),
      ),
    );
  }
}

extension DayOfYear on DateTime {
  int get dayOfYear {
    final start = DateTime(year, 1, 1);
    return difference(start).inDays + 1;
  }
}
