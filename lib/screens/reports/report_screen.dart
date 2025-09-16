import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:money_note/constants/date_filter_option.dart';
import 'package:money_note/components/reports/report_chart.dart';
import 'package:money_note/components/reports/report_filter.dart';
import 'package:money_note/components/transactions/transaction_summary_card.dart';
import 'package:money_note/components/reports/report_list.dart';
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

  String groupBy = "day";
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
          setState(() {
            transactions = txList.map((tx) => tx.toMap()).toList();
            debugPrint(transactions.toString());
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
      late DateTime date;

      if (rawDate is Timestamp) {
        date = rawDate.toDate();
      } else if (rawDate is DateTime) {
        date = rawDate;
      } else {
        throw Exception("Unknown date type: $rawDate");
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
    setState(() {
      selectedRange = option;
      selectedLabel = label;
      fromDate = from;
      toDate = to;
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
        bottom: ReportFilter(
          groupBy: "month",
          selectedRange: DateFilterOption.thisMonth,
          onDateRangePicked: _applyDateFilter,
          onGroupChanged: (group) {
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
        ],
      ),
    );
  }
}

extension DayOfYear on DateTime {
  int get dayOfYear => int.parse(DateFormat("D").format(this));
}
