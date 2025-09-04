import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../services/budget_service.dart';
import '../../services/category_service.dart';
import '../../components/forms/currency_text_field.dart';
import '../../components/forms/month_picker_field.dart';
import '../../../utils/currency_formatter.dart';
import '../../components/buttons/submit_button.dart';

class BudgetFormScreen extends StatefulWidget {
  final Budget? budget;

  const BudgetFormScreen({super.key, this.budget});

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedCategoryId;
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    if (widget.budget != null) {
      _selectedCategoryId = widget.budget!.categoryId;
      _amountController.text = widget.budget!.amount.toString();
      _selectedMonth = widget.budget!.month;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final amount = CurrencyFormatter().decodeAmount(_amountController.text);

    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'demoUser';
    final budget = Budget(
      id: widget.budget?.id ?? '',
      categoryId: _selectedCategoryId!,
      amount: amount,
      month: DateTime(_selectedMonth.year, _selectedMonth.month),
      userId: userId,
    );

    if (widget.budget == null) {
      final exists = await BudgetService().checkDuplicateBudget(
        budget.categoryId,
        budget.month,
      );
      if (exists) {
        setState(() {
          _errorText = 'There is no nudget for this category in this month.';
          _isLoading = false;
        });
        return;
      }
      await BudgetService().addBudget(budget);
    } else {
      await BudgetService().updateBudget(budget);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.budget != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Budget' : 'Add Budget'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Dropdown kategori
              StreamBuilder<List<Category>>(
                stream: CategoryService().getCategoryStream(type: 'expense'),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      isDense: true,
                    ),
                    items:
                        items.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }).toList(),
                    validator: (val) => val == null ? 'Select Category' : null,
                    onChanged:
                        (val) => setState(() => _selectedCategoryId = val),
                  );
                },
              ),
              const SizedBox(height: 16),

              CurrencyTextField(
                controller: _amountController,
                label: 'Amount',
                validator:
                    (val) =>
                        val == null || val.trim().isEmpty
                            ? 'Amount is required'
                            : null,
              ),
              const SizedBox(height: 16),
              MonthPickerField(
                selectedMonth: _selectedMonth,
                onMonthPicked: (picked) {
                  setState(() => _selectedMonth = picked);
                },
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(_errorText!, style: const TextStyle(color: Colors.red)),
              ],
              const Spacer(),

              // Tombol simpan
              SizedBox(
                width: double.infinity,
                child: SubmitButton(
                  isSubmitting: _isLoading,
                  onPressed: _saveBudget,
                  label: isEdit ? 'Update' : 'Save',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
