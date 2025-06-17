import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import 'add_transaction_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({Key? key}) : super(key: key);

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  DateTime? _from;
  DateTime? _to;
  String _label = 'Semua';

  Future<void> _pickFilter() async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width,
        kToolbarHeight + 24,
        16,
        0,
      ),
      items: const [
        PopupMenuItem(value: 'today', child: Text('Hari Ini')),
        PopupMenuItem(value: '7days', child: Text('7 Hari Terakhir')),
        PopupMenuItem(value: '30days', child: Text('30 Hari Terakhir')),
        PopupMenuItem(value: 'thismonth', child: Text('Bulan Ini')),
        PopupMenuItem(value: 'lastmonth', child: Text('Bulan Lalu')),
        PopupMenuItem(value: 'custom', child: Text('Kustom...')),
      ],
    );

    if (selected == null) return;

    final now = DateTime.now();
    switch (selected) {
      case 'today':
        setState(() {
          _from = DateTime(now.year, now.month, now.day);
          _to = _from!.add(const Duration(days: 1));
          _label = 'Hari Ini';
        });
        break;
      case '7days':
        setState(() {
          _from = now.subtract(const Duration(days: 6));
          _to = now.add(const Duration(days: 1));
          _label = '7 Hari Terakhir';
        });
        break;
      case '30days':
        setState(() {
          _from = now.subtract(const Duration(days: 29));
          _to = now.add(const Duration(days: 1));
          _label = '30 Hari Terakhir';
        });
        break;
      case 'thismonth':
        setState(() {
          _from = DateTime(now.year, now.month);
          _to = DateTime(now.year, now.month + 1);
          _label = 'Bulan Ini';
        });
        break;
      case 'lastmonth':
        final lastMonth = DateTime(now.year, now.month - 1);
        setState(() {
          _from = DateTime(lastMonth.year, lastMonth.month);
          _to = DateTime(lastMonth.year, lastMonth.month + 1);
          _label = 'Bulan Lalu';
        });
        break;
      case 'custom':
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          saveText: 'Terapkan',
        );
        if (picked != null) {
          setState(() {
            _from = picked.start;
            _to = picked.end.add(const Duration(days: 1));
            _label =
                '${DateFormat('dd MMM').format(picked.start)} - ${DateFormat('dd MMM yyyy').format(picked.end)}';
          });
        }
        break;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getTransactions() {
    return TransactionService().getTransactions(fromDate: _from, toDate: _to);
  }

  Future<void> _showTransactionMenu(
    BuildContext context,
    String docId,
    Map<String, dynamic> trx,
  ) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(200, 300, 0, 0),
      items: const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Hapus')),
      ],
    );

    if (selected == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  AddTransactionScreen(transactionId: docId, existingData: trx),
        ),
      );
    } else if (selected == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Hapus Transaksi'),
              content: const Text('Yakin ingin menghapus transaksi ini?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Hapus'),
                ),
              ],
            ),
      );
      if (confirm == true) {
        await TransactionService().deleteTransaction(docId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaksi dihapus')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        elevation: 0,
        title: const Text(
          'Transaksi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          GestureDetector(
            onTap: _pickFilter,
            child: Row(
              children: [
                const Icon(Icons.date_range, color: Colors.white, size: 20),
                const SizedBox(width: 4),
                Text(_label, style: const TextStyle(color: Colors.white)),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.docs ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('Belum ada transaksi'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            itemBuilder: (ctx, i) {
              final doc = data[i];
              final trx = doc.data();
              final isIncome = trx['type'] == 'income';
              final date = (trx['date'] as Timestamp).toDate();

              return GestureDetector(
                onTap: () => _showTransactionMenu(context, doc.id, trx),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      trx['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(date)),
                    trailing: Text(
                      NumberFormat.currency(
                        locale: 'id',
                        symbol: 'Rp',
                      ).format(trx['amount']),
                      style: TextStyle(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
            ),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white, // <-- Set the icon/text color here
        child: const Icon(Icons.add),
      ),
    );
  }
}
