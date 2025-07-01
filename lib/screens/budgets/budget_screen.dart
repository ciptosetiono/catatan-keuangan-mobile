import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/category_model.dart';
import '../../services/category_service.dart';
import 'budget_form_screen.dart';
import '../../components/budgets/budget_list.dart';
import '../../components/budgets/budget_month_dropdown.dart';
import '../../components/budgets/budget_category_dropdown.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  DateTime _selectedMonth = DateTime.now();
  String _selectedCategoryId = '';
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    CategoryService().getCategoryStream(type: 'expense').listen((cats) {
      setState(() {
        _categories = cats;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggaran'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: BudgetMonthDropdown(
                    selectedMonth: _selectedMonth,
                    onChanged: (val) => setState(() => _selectedMonth = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BudgetCategoryDropdown(
                    selectedCategoryId: _selectedCategoryId,
                    categories: _categories,
                    onChanged:
                        (val) => setState(() => _selectedCategoryId = val),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BudgetList(
              selectedMonth: _selectedMonth,
              selectedCategoryId: _selectedCategoryId,
              categories: _categories,
              userId: userId,
            ),
          ),
        ],
      ),
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
