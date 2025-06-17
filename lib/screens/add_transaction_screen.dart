import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import '../services/firestore_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? transactionId;
  final Map<String, dynamic>? existingData;

  const AddTransactionScreen({
    super.key,
    this.transactionId,
    this.existingData,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'expense';
  String? _category;
  DateTime _selectedDate = DateTime.now();
  List<String> _categories = [];

  bool get isEdit => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (isEdit && widget.existingData != null) {
      _initializeForm(widget.existingData!);
    }
  }

  void _initializeForm(Map<String, dynamic> data) {
    _titleController.text = data['title'] ?? '';
    final amount = data['amount'] ?? 0;
    _amountController.text = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
    ).format(amount);
    _type = data['type'] ?? 'expense';
    _category = data['category'];
    _selectedDate = (data['date']).toDate(); // assume Timestamp
  }

  Future<void> _loadCategories() async {
    final items = await FirestoreService().getCategories();
    setState(() => _categories = items);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _category == null) return;

    final amount = double.tryParse(
      _amountController.text
          .replaceAll("Rp", "")
          .replaceAll(".", "")
          .replaceAll(",", "."),
    );
    if (amount == null) return;

    final data = {
      'title': _titleController.text.trim(),
      'amount': amount,
      'type': _type,
      'category': _category!,
      'date': _selectedDate,
    };

    if (isEdit) {
      await TransactionService().updateTransaction(widget.transactionId!, data);
    } else {
      await TransactionService().addTransactionFromMap(data);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  filled: true,
                  border: OutlineInputBorder(),
                ),
                validator:
                    (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  filled: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                  final formatted = NumberFormat.currency(
                    locale: 'id',
                    symbol: 'Rp',
                  ).format(int.tryParse(clean) ?? 0);
                  _amountController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(
                      offset: formatted.length,
                    ),
                  );
                },
                validator:
                    (val) =>
                        val == null || val.isEmpty
                            ? 'Jumlah harus diisi'
                            : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                  DropdownMenuItem(
                    value: 'expense',
                    child: Text('Pengeluaran'),
                  ),
                ],
                onChanged: (val) => setState(() => _type = val!),
                decoration: const InputDecoration(
                  labelText: 'Tipe',
                  filled: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                items:
                    _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                onChanged: (val) => setState(() => _category = val),
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  filled: true,
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tanggal'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                  ),
                  onPressed: _submit,
                  child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
