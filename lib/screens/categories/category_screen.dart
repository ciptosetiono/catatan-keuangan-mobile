import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import 'category_form_screen.dart';
import '../../components/buttons/add_button.dart';
import '../../components/categories/category_list.dart';
import '../../components/categories/category_filter_bar.dart';
import '../../components/categories/category_action_dialog.dart';
import '../../components/forms/delete_confirmation_dialog.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryService _categoryService = CategoryService();
  String _searchQuery = '';
  String _filterType = 'all';

  Future<void> _handleCategoryTap(
    BuildContext context,
    Category category,
  ) async {
    final selected = await showCategoryActionDialog(context);

    if (selected == 'edit') {
      _openCategoryForm(category: category);
    } else if (selected == 'delete') {
      _deleteCategory(category);
    }
  }

  void _openCategoryForm({Category? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoryFormScreen(category: category)),
    );
  }

  void _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => DeleteConfirmationDialog(
            title: 'Delete Category',
            content: 'Are You sure You want to delete this category?',
            onCancel: () => Navigator.pop(ctx, false),
            onDelete: () => Navigator.pop(ctx, true),
          ),
    );
    if (confirm == true) {
      await _categoryService.deleteCategory(category.id);
    }
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
        categoryService: _categoryService,
        searchQuery: _searchQuery,
        filterType: _filterType,
        onCategoryTap: _handleCategoryTap,
      ),
      floatingActionButton: AddButton(onPressed: _openCategoryForm),
    );
  }
}
