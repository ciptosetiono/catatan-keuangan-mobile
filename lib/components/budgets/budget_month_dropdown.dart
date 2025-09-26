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
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateTime>(
          value: DateTime(selectedMonth.year, selectedMonth.month),
          isExpanded: true,
          icon: const SizedBox.shrink(), // hide default arrow
          items: List.generate(12, (i) {
            final date = DateTime(DateTime.now().year, i + 1);
            return DropdownMenuItem<DateTime>(
              value: DateTime(date.year, date.month),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM yyyy').format(date),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}
