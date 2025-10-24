import 'dart:async';
import 'package:flutter/material.dart';

import 'package:money_note/models/category_model.dart';

import 'package:money_note/services/sqlite/category_service.dart';
import 'package:money_note/components/ads/banner_ad_widget.dart';
import 'package:money_note/components/buttons/add_button.dart';
import 'package:money_note/components/budgets/budget_list.dart';
import 'package:money_note/components/budgets/budget_category_name_filter.dart';
import 'package:money_note/screens/budgets/budget_form_screen.dart';
import 'package:money_note/components/forms/month_picker_field.dart';

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // 🔹 Category name filter
                Expanded(
                  flex: 2,
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

                // 🔹 Month picker icon/button
                SizedBox(
                  width: 48,
                  height: 48,
                  child: MonthPickerField(
                    selectedMonth: _selectedMonth,
                    onMonthPicked: (picked) {
                      setState(() => _selectedMonth = picked);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // main content
          Padding(
            padding: const EdgeInsets.only(bottom: 60), // space for ad
            child: BudgetList(
              selectedMonth: _selectedMonth,
              categories: _categories,
            ),
          ),

          // ✅ Fixed banner ad at bottom
          const Align(
            alignment: Alignment.bottomCenter,
            child: BannerAdWidget(),
          ),
        ],
      ),
      floatingActionButton: AddButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BudgetFormScreen()),
          );
        },
      ),
    );
  }
}
