import 'package:flutter/material.dart';

class FilterButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;

  const FilterButton({super.key, this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48, // match date filter field height
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color.fromARGB(255, 78, 78, 78),
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        icon: const Icon(
          Icons.filter_list,
          size: 20,
          color: Color.fromARGB(255, 78, 78, 78),
        ),
        label: Text(
          label ?? '',
          style: const TextStyle(
            color: Color.fromARGB(255, 78, 78, 78),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
