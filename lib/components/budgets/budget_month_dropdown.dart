import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetMonthDropdown extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onChanged;

  const BudgetMonthDropdown({
    super.key,
    required this.selectedMonth,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<DateTime>(
            value: DateTime(selectedMonth.year, selectedMonth.month),
            isExpanded: true,
            icon: const Icon(Icons.calendar_today),
            items: List.generate(12, (i) {
              final date = DateTime(DateTime.now().year, i + 1);
              return DropdownMenuItem<DateTime>(
                value: DateTime(date.year, date.month),
                child: Text(DateFormat('MMM yyyy').format(date)),
              );
            }),
            onChanged: (val) {
              if (val != null) {
                onChanged(val);
              }
            },
          ),
        ),
      ),
    );
  }
}
