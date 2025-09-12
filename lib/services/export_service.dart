import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportService {
  /// Export transactions to CSV
  static Future<void> exportToCsv(
    List<Map<String, dynamic>> transactions,
  ) async {
    List<List<dynamic>> rows = [
      ["Date", "Title", "Category", "Account", "Type", "Amount"],
    ];

    for (var tx in transactions) {
      rows.add([
        tx["date"] ?? "",
        tx["title"] ?? "",
        tx["categoryName"] ?? "",
        tx["accountName"] ?? "",
        tx["type"] ?? "",
        tx["amount"] ?? 0,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/transactions.csv");
    await file.writeAsString(csv);

    Share.shareXFiles([
      XFile(file.path),
    ], text: "My exported transactions (CSV).");
  }

  /// Export transactions to PDF
  static Future<void> exportToPdf(
    List<Map<String, dynamic>> transactions,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build:
            (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Transaction Report",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Table.fromTextArray(
                  headers: [
                    "Date",
                    "Title",
                    "Category",
                    "Account",
                    "Type",
                    "Amount",
                  ],
                  data:
                      transactions
                          .map(
                            (tx) => [
                              tx["date"] ?? "",
                              tx["title"] ?? "",
                              tx["categoryName"] ?? "",
                              tx["accountName"] ?? "",
                              tx["type"] ?? "",
                              tx["amount"]?.toString() ?? "0",
                            ],
                          )
                          .toList(),
                ),
              ],
            ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'transactions.pdf',
    );
  }
}
