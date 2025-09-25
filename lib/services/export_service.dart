// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:money_note/utils/currency_formatter.dart';
import 'package:share_plus/share_plus.dart';

class ReportExportService {
  CurrencyFormatter currencyFormatter = CurrencyFormatter();

  String dateFormat(Object? date) {
    DateTime trxDate;
    if (date is DateTime) {
      trxDate = date;
    } else if (date is String) {
      trxDate = DateTime.tryParse(date) ?? DateTime.now();
    } else if (date is Timestamp) {
      trxDate = date.toDate();
    } else {
      trxDate = DateTime.now();
    }
    return DateFormat('yyyy-MM-dd').format(trxDate);
  }

  Future<void> exportToCsv({
    required List<Map<String, dynamic>> transactions,
    String fileName = 'report.csv',
  }) async {
    final csvData = [
      ['Date', 'Title', 'Type', 'Amount', 'Category', 'Wallet'],
    ];

    for (var trx in transactions) {
      csvData.add([
        dateFormat(trx['date']),
        trx['title'] ?? '',
        trx['type'] ?? '',
        (trx['amount'] ?? 0).toString(),
        trx['categoryName'] ?? '',
        trx['walletName'] ?? '',
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvString);

    // langsung share
    await Share.shareXFiles([XFile(file.path)], text: "Moneyger Report");
  }

  /// Export transaksi ke PDF
  Future<void> exportToPdf({
    required List<Map<String, dynamic>> transactions,
    // required DateTime start,
    //required DateTime end,
    String fileName = 'Moneyger-report.pdf',
  }) async {
    final pdf = pw.Document();

    final filtered = transactions.toList();

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Text(
                'Moneyger Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: [
                  'Date',
                  'Title',
                  'Type',
                  'Amount',
                  'Category',
                  'Wallet',
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: {
                  0: const pw.FlexColumnWidth(2), // Date
                  1: const pw.FlexColumnWidth(4), // Title
                  2: const pw.FlexColumnWidth(2), // Type
                  3: const pw.FlexColumnWidth(3), // Amount
                  4: const pw.FlexColumnWidth(3), // Category
                  5: const pw.FlexColumnWidth(3), // Wallet
                },
                data:
                    filtered.map((trx) {
                      return [
                        dateFormat(trx['date']),
                        trx['title'] ?? '',
                        trx['type'] ?? '',
                        (trx['amount'] ?? 0).toString(),
                        trx['categoryName'] ?? '',
                        trx['walletName'] ?? '',
                      ];
                    }).toList(),
              ),
            ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');

    final bytes = await pdf.save();
    await file.writeAsBytes(await pdf.save());

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}
