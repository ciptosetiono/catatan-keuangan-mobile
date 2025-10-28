import 'package:flutter/material.dart';
import 'month_picker.dart';

class MonthPickerField extends StatelessWidget {
  final DateTime selectedMonth;
  final void Function(DateTime) onMonthPicked;

  const MonthPickerField({
    super.key,
    required this.selectedMonth,
    required this.onMonthPicked,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50, // match the height of other filters
      child: MonthPicker(
        selectedMonth: selectedMonth,
        onMonthPicked: onMonthPicked,
      ),
    );
  }
}
