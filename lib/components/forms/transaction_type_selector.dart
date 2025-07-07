import 'package:flutter/material.dart';

class TransactionTypeSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const TransactionTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children:
          ['income', 'expense'].map((type) {
            final isSelected = selected == type;
            final color = type == 'income' ? Colors.green : Colors.red;
            final label = type == 'income' ? 'Pemasukan' : 'Pengeluaran';

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  // ignore: deprecated_member_use
                  selectedColor: color.withOpacity(0.2),
                  onSelected: (_) => onChanged(type),
                  labelStyle: TextStyle(
                    color: isSelected ? color : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? color : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
