import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/category_model.dart';
import '../../services/category_service.dart';
import 'budget_form_screen.dart';
import '../../components/budgets/budget_list.dart';
import '../../components/budgets/budget_month_dropdown.dart';
import '../../components/budgets/budget_category_name_filter.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  DateTime _selectedMonth = DateTime.now();
  String _categoryName = '';
  Timer? _debounce;
  List<Category> _categories = [];
  late final StreamSubscription _categorySubscription;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    _categorySubscription = CategoryService()
        .getCategoryStream(type: 'expense', query: _categoryName)
        .listen((cats) {
          setState(() {
            _categories = cats;
          });
        });
  }

  @override
  void dispose() {
    _categorySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: BudgetCategoryNameField(
                    categoryName: _categoryName,
                    onChanged: (val) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        _categorySubscription.cancel();
                        setState(() {
                          _categoryName = val;
                          _loadCategories();
                        });
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BudgetMonthDropdown(
                    selectedMonth: _selectedMonth,
                    onChanged: (val) => setState(() => _selectedMonth = val),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: BudgetList(selectedMonth: _selectedMonth, categories: _categories),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BudgetFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
