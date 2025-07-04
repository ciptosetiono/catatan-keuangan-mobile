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
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        textAlignVertical: TextAlignVertical.center,
        decoration: const InputDecoration(
          hintText: 'search category...',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
