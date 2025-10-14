import 'package:flutter/material.dart';

import 'package:money_note/models/category_model.dart';
import 'package:money_note/components/buttons/add_button.dart';
import 'package:money_note/components/categories/category_list.dart';
import 'package:money_note/components/categories/category_filter_bar.dart';
import 'package:money_note/components/categories/category_action_dialog.dart';
import 'package:money_note/components/categories/category_delete_dialog.dart';
import 'package:money_note/screens/categories/category_detail_screen.dart';
import 'package:money_note/screens/categories/category_form_screen.dart';
import 'package:money_note/components/ads/banner_ad_widget.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _searchQuery = '';
  String _filterType = 'all';

  Future<void> _handleCategoryTap(
    BuildContext context,
    Category category,
  ) async {
    final selected = await showCategoryActionDialog(context);

    if (selected == 'detail') {
      _openCategoryDetail(category);
    } else if (selected == 'edit') {
      _openCategoryForm(category: category);
    } else if (selected == 'delete') {
      _deleteCategory(category);
    }
  }

  void _openCategoryDetail(Category category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDetailScreen(category: category),
      ),
    );

    if (result == true) {}
  }

  void _openCategoryForm({Category? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoryFormScreen(category: category)),
    );
  }

  void _deleteCategory(Category category) async {
    await confirmAndDeleteCategory(
      context: context,
      categoryId: category.id,
      onDeleted: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: CategoryFilterBar(
            searchQuery: _searchQuery,
            filterType: _filterType,
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            onFilterChanged: (val) => setState(() => _filterType = val),
          ),
        ),
      ),
      body: CategoryList(
        searchQuery: _searchQuery,
        filterType: _filterType,
        onCategoryTap: _handleCategoryTap,
      ),
      bottomNavigationBar: const BannerAdWidget(),
      floatingActionButton: AddButton(onPressed: _openCategoryForm),
    );
  }
}
