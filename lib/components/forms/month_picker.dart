import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';

class MonthPicker extends StatelessWidget {
  final DateTime selectedMonth;
  final String? labelText;
  final void Function(DateTime) onMonthPicked;

  const MonthPicker({
    super.key,
    required this.selectedMonth,
    this.labelText,
    required this.onMonthPicked,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat.yMMMM('en_US').format(selectedMonth);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showMonthYearPicker(
          context: context,
          initialDate: selectedMonth,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );

        if (picked != null) onMonthPicked(picked);
      },
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month,
            color: Color.fromARGB(255, 112, 112, 112),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              formatted,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
