import 'package:flutter/material.dart';
import 'month_picker.dart';

class MonthPickerFilter extends StatelessWidget {
  final DateTime selectedMonth;
  final void Function(DateTime) onMonthPicked;

  const MonthPickerFilter({
    super.key,
    required this.selectedMonth,
    required this.onMonthPicked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48, // fixed height
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300), // single border
      ),
      child: MonthPicker(
        selectedMonth: selectedMonth,
        onMonthPicked: onMonthPicked,
      ),
    );
  }
}
