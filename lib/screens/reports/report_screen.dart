import 'package:flutter/material.dart';
import 'package:money_note/constants/date_filter_option.dart';
import 'package:money_note/components/reports/report_chart.dart';
import 'package:money_note/components/reports/report_filter.dart';
import 'package:money_note/components/reports/report_list.dart';
import 'package:money_note/components/reports/report_summary.dart';
import 'package:money_note/services/transaction_service.dart';

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

  String groupBy = "month";
  List<Map<String, dynamic>> transactions = [];

  double income = 0;
  double expense = 0;
  double balance = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    TransactionService()
        .getTransactionsStream(fromDate: fromDate, toDate: toDate)
        .listen((txList) {
          transactions = txList.map((tx) => tx.toMap()).toList();
          _calculateSummary();
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

  void _applyDateFilter(
    DateFilterOption option, {
    DateTime? from,
    DateTime? to,
    String? label,
  }) {
    setState(() {
      selectedRange = option;
      selectedLabel = label;
      from = from;
      to = to;
    });
    _loadTransactions();
  }

  void _export(String type) {
    /*
    final exportService = ReportExportService(
      transactions: transactions,
      income: income,
      expense: expense,
      balance: balance,
      range: selectedRange,
    );

    if (type == "csv") exportService.shareCsv();
    if (type == "pdf") exportService.sharePdf();
    if (type == "pdf_preview") exportService.previewPdf();
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report"), // kosong atau back button
        actions: [
          PopupMenuButton<String>(
            onSelected: _export,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: "csv",
                    child: Text("Export as CSV"),
                  ),
                  const PopupMenuItem(
                    value: "pdf",
                    child: Text("Export as PDF"),
                  ),
                  const PopupMenuItem(
                    value: "pdf_preview",
                    child: Text("Preview PDF"),
                  ),
                ],
            icon: const Icon(Icons.share),
          ),
        ],
        bottom: ReportFilter(
          groupBy: "month",
          selectedRange: DateFilterOption.thisMonth,
          onDateRangePicked: _applyDateFilter,
          onGroupChanged: (group) {
            // update data laporan sesuai groupBy
          },
        ),
      ),
      body: Column(
        children: [
          ReportSummary(income: income, expense: expense, balance: balance),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ReportChart(transactions: transactions),
            ),
          ),
          Expanded(flex: 1, child: ReportList(transactions: transactions)),
        ],
      ),
    );
  }
}
