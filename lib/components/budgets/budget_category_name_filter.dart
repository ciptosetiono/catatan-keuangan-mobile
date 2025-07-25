import 'package:flutter/material.dart';

class BudgetCategoryNameField extends StatelessWidget {
  final String categoryName;
  final ValueChanged<String> onChanged;

  const BudgetCategoryNameField({
    super.key,
    required this.categoryName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42, // Sedikit lebih kecil dari sebelumnya
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: TextField(
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Search category...',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
