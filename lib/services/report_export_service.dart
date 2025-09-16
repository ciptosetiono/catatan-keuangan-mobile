// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportExportService {
  /// Export transaksi ke CSV
  Future<String> exportToCsv({
    required List<Map<String, dynamic>> transactions,
    required DateTime start,
    required DateTime end,
    String fileName = 'report.csv',
  }) async {
    final csvData = [
      ['Date', 'Title', 'Type', 'Amount', 'Category', 'Wallet'],
    ];

    final formatter = DateFormat('yyyy-MM-dd');

    for (var trx in transactions) {
      final trxDate = trx['date'] as DateTime;
      if (trxDate.isAfter(end) || trxDate.isBefore(start)) continue;

      csvData.add([
        formatter.format(trxDate),
        trx['title'] ?? '',
        trx['type'] ?? '',
        trx['amount'] ?? 0,
        trx['category'] ?? '',
        trx['wallet'] ?? '',
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvString);

    // Share file
    //await Share.shareFiles([file.path], text: 'My Transaction Report');

    return file.path;
  }

  /// Export transaksi ke PDF
  Future<void> exportToPdf({
    required List<Map<String, dynamic>> transactions,
    required DateTime start,
    required DateTime end,
    String fileName = 'report.pdf',
  }) async {
    final pdf = pw.Document();
    final formatter = DateFormat('yyyy-MM-dd');

    final filtered =
        transactions.where((trx) {
          final trxDate = trx['date'] as DateTime;
          return !(trxDate.isBefore(start) || trxDate.isAfter(end));
        }).toList();

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Text(
                'Transaction Report',
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
                data:
                    filtered.map((trx) {
                      return [
                        formatter.format(trx['date'] as DateTime),
                        trx['title'] ?? '',
                        trx['type'] ?? '',
                        trx['amount'] ?? 0,
                        trx['category'] ?? '',
                        trx['wallet'] ?? '',
                      ];
                    }).toList(),
              ),
            ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
  }
}
