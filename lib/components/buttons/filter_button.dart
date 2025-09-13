import 'package:flutter/material.dart';

class FilterButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const FilterButton({super.key, this.label = 'Filter', this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 15, 15, 15),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            8,
          ), // nilai lebih kecil → radius lebih kecil
        ),
      ),
      icon: const Icon(Icons.filter_list),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
