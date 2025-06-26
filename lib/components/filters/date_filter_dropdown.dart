import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/date_filter_option.dart';

class DateFilterDropdown extends StatelessWidget {
  final DateFilterOption selected;
  final Function(
    DateFilterOption option, {
    DateTime? from,
    DateTime? to,
    String? label,
  })
  onFilterApplied;

  const DateFilterDropdown({
    Key? key,
    required this.selected,
    required this.onFilterApplied,
  }) : super(key: key);

  void _handleChange(BuildContext context, DateFilterOption option) async {
    final now = DateTime.now();
    DateTime? from;
    DateTime? to;
    String label = '';

    switch (option) {
      case DateFilterOption.today:
        from = DateTime(now.year, now.month, now.day);
        to = from.add(const Duration(days: 1));
        label = 'Hari Ini';
        break;
      case DateFilterOption.thisMonth:
        from = DateTime(now.year, now.month);
        to = DateTime(now.year, now.month + 1);
        label = 'Bulan Ini';
        break;
      case DateFilterOption.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1);
        from = DateTime(lastMonth.year, lastMonth.month);
        to = DateTime(now.year, now.month);
        label = 'Bulan Lalu';
        break;
      case DateFilterOption.last30Days:
        from = now.subtract(const Duration(days: 30));
        to = now.add(const Duration(days: 1));
        label = '30 Hari Terakhir';
        break;
      case DateFilterOption.thisYear:
        from = DateTime(now.year);
        to = DateTime(now.year + 1);
        label = 'Tahun Ini';
        break;
      case DateFilterOption.all:
        from = null;
        to = null;
        label = 'Semua';
        break;
      case DateFilterOption.custom:
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: now.add(const Duration(days: 365)),
        );
        if (picked != null) {
          from = picked.start;
          to = picked.end.add(const Duration(days: 1));
          label =
              '${DateFormat('dd MMM').format(picked.start)} - ${DateFormat('dd MMM yyyy').format(picked.end)}';
        } else {
          return;
        }
        break;
    }

    onFilterApplied(option, from: from, to: to, label: label);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Icon(Icons.date_range, color: Colors.black),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DateFilterOption>(
                value: selected,
                isExpanded: true,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),
                icon: const SizedBox.shrink(), // hide default icon
                items:
                    DateFilterOption.values.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(
                          e == DateFilterOption.custom
                              ? 'Custom...'
                              : e
                                  .toString()
                                  .split('.')
                                  .last
                                  .replaceAll('thisMonth', 'Bulan Ini')
                                  .replaceAll('lastMonth', 'Bulan Lalu')
                                  .replaceAll('last30Days', '30 Hari')
                                  .replaceAll('thisYear', 'Tahun Ini')
                                  .replaceAll('today', 'Hari Ini')
                                  .replaceAll('all', 'Semua'),
                        ),
                      );
                    }).toList(),
                onChanged: (option) {
                  if (option != null) {
                    _handleChange(context, option);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
