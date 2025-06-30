import 'package:flutter/material.dart';
import '../../../models/category_model.dart';

class BudgetCategoryDropdown extends StatelessWidget {
  final String selectedCategoryId;
  final List<Category> categories;
  final ValueChanged<String> onChanged;

  const BudgetCategoryDropdown({
    super.key,
    required this.selectedCategoryId,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedCategoryId,
            isExpanded: true,
            icon: const Icon(Icons.category),
            items: [
              const DropdownMenuItem(value: '', child: Text('Semua Kategori')),
              ...categories.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
      ),
    );
  }
}
