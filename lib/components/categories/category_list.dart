import 'package:flutter/material.dart';

import 'package:money_note/models/category_model.dart';

import 'package:money_note/services/firebase/category_service.dart';

import 'package:money_note/components/categories/category_list_item.dart';

class CategoryList extends StatelessWidget {
  final CategoryService categoryService;
  final String searchQuery;
  final String filterType;
  final void Function(BuildContext, Category) onCategoryTap;

  const CategoryList({
    super.key,
    required this.categoryService,
    required this.searchQuery,
    required this.filterType,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Category>>(
      stream: categoryService.getCategoryStream(
        query: searchQuery,
        type: filterType,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return const Center(
            child: Text('There are no categories yet. Add one now!'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: categories.length,
          itemBuilder: (ctx, i) {
            final category = categories[i];
            return CategoryListItem(
              category: category,
              onTap: () => onCategoryTap(context, category),
            );
          },
        );
      },
    );
  }
}
