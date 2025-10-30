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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Select Month',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 55, // fixed height
          decoration: BoxDecoration(
            color: Colors.grey[100], // background color
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300, // customize the border color
              width: 1.2, // border thickness
            ),
          ),
          child: MonthPicker(
            selectedMonth: selectedMonth,
            onMonthPicked: onMonthPicked,
          ),
        ),
      ],
    );
  }
}
