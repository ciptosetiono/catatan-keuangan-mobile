import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:money_note/components/reports/report_chart.dart';
import 'package:money_note/components/reports/report_filter.dart';
import 'package:money_note/components/reports/report_list.dart';
import 'package:money_note/components/reports/report_summary.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTimeRange? selectedRange;
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
    final userId =
        "dummyUser"; // ganti dengan FirebaseAuth.instance.currentUser!.uid

    Query query = FirebaseFirestore.instance
        .collection("transactions")
        .where("userId", isEqualTo: userId);

    if (selectedRange != null) {
      query = query
          .where("date", isGreaterThanOrEqualTo: selectedRange!.start)
          .where("date", isLessThanOrEqualTo: selectedRange!.end);
    }

    final snapshot = await query.get();
    transactions =
        snapshot.docs.map((doc) {
          return {"id": doc.id, ...doc.data() as Map<String, dynamic>};
        }).toList();

    _calculateSummary();
    setState(() {});
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
        title: const Text("Report"),
        actions: [
          PopupMenuButton<String>(
            onSelected: _export,
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: "csv", child: Text("Export CSV")),
                  PopupMenuItem(value: "pdf", child: Text("Export PDF")),
                  PopupMenuItem(
                    value: "pdf_preview",
                    child: Text("Preview PDF"),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          ReportFilter(
            selectedRange: selectedRange,
            groupBy: groupBy,
            onDateRangePicked: (range) {
              setState(() => selectedRange = range);
              _loadTransactions();
            },
            onGroupChanged: (v) {
              setState(() => groupBy = v);
              _loadTransactions();
            },
          ),
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
