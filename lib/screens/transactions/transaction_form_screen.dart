import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../components/forms/transaction_type_selector.dart';
import '../../../components/forms/wallet_dropdown.dart';
import '../../../components/forms/date_picker_field.dart';

import '../../../services/transaction_service.dart';
import '../../../services/category_service.dart';
import '../../../models/category_model.dart';
import '../../../models/wallet_model.dart';
import '../../../services/wallet_service.dart';
import '../../components/forms/currency_text_field.dart';

class TransactionFormScreen extends StatefulWidget {
  final String? transactionId;
  final Map<String, dynamic>? existingData;

  const TransactionFormScreen({Key? key, this.transactionId, this.existingData})
    : super(key: key);

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  String _type = 'expense';
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  String? _selectedWalletId;

  List<Category> _categories = [];
  List<Wallet> _wallets = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    if (widget.existingData != null) {
      final data = widget.existingData!;
      _titleController.text = data['title'] ?? '';
      _amountController.text = data['amount'].toString();
      _type = data['type'] ?? 'expense';
      _selectedCategoryId = data['categoryId'];
      _selectedWalletId = data['walletId'];
      _selectedDate = (data['date'] as Timestamp).toDate();
    }
  }

  Future<void> _loadInitialData() async {
    CategoryService().getCategoryStream(type: _type).listen((list) {
      setState(() => _categories = list);
    });

    WalletService().getWalletStream().listen((list) {
      setState(() => _wallets = list);
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kategori dan akun terlebih dahulu'),
        ),
      );
      return;
    }

    final title = _titleController.text.trim();
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final trx = {
      'title': title,
      'amount': amount,
      'type': _type,
      'date': _selectedDate,
      'categoryId': _selectedCategoryId,
      'walletId': _selectedWalletId,
      'userId': userId,
    };

    if (widget.transactionId != null) {
      await TransactionService().updateTransaction(widget.transactionId!, trx);
    } else {
      await TransactionService().addTransaction(
        title: title,
        amount: amount,
        type: _type,
        categoryId: _selectedCategoryId!,
        walletId: _selectedWalletId!,
        date: _selectedDate,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transactionId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TransactionTypeSelector(
                selected: _type,
                onChanged: (val) {
                  setState(() {
                    _type = val;
                    _selectedCategoryId = null;
                    _loadInitialData();
                  });
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (val) =>
                        val == null || val.trim().isEmpty
                            ? 'Judul wajib diisi'
                            : null,
              ),
              const SizedBox(height: 16),

              CurrencyTextField(
                controller: _amountController,
                label: 'Jumlah',
                validator:
                    (val) =>
                        val == null || val.trim().isEmpty
                            ? 'Jumlah wajib diisi'
                            : null,
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items:
                    _categories
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.name),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 16),

              WalletDropdown(
                value: _selectedWalletId,
                onChanged: (val) => setState(() => _selectedWalletId = val),
              ),
              const SizedBox(height: 16),

              DatePickerField(
                selectedDate: _selectedDate,
                onDatePicked:
                    (picked) => setState(() => _selectedDate = picked),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  label: const Text('Simpan Transaksi'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
