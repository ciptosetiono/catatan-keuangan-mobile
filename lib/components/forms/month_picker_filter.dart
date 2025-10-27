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
      constraints: const BoxConstraints(minHeight: 48),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: MonthPicker(
        selectedMonth: selectedMonth,
        onMonthPicked: onMonthPicked,
      ),
    );
  }
}
