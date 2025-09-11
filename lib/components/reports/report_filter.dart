import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportFilter extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final String groupBy;
  final Function(DateTimeRange) onDateRangePicked;
  final Function(String) onGroupChanged;

  const ReportFilter({
    super.key,
    required this.selectedRange,
    required this.groupBy,
    required this.onDateRangePicked,
    required this.onGroupChanged,
  });

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          selectedRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (picked != null) {
      onDateRangePicked(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ElevatedButton(
          onPressed: () => _pickDateRange(context),
          child: Text(
            selectedRange != null
                ? "${DateFormat("MM/dd").format(selectedRange!.start)} - ${DateFormat("MM/dd").format(selectedRange!.end)}"
                : "Select Date",
          ),
        ),
        DropdownButton<String>(
          value: groupBy,
          items: const [
            DropdownMenuItem(value: "day", child: Text("Per Day")),
            DropdownMenuItem(value: "week", child: Text("Per Week")),
            DropdownMenuItem(value: "month", child: Text("Per Month")),
            DropdownMenuItem(value: "year", child: Text("Per Year")),
          ],
          onChanged: (v) {
            if (v != null) onGroupChanged(v);
          },
        ),
      ],
    );
  }
}
