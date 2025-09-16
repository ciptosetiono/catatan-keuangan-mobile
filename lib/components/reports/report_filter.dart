import 'package:flutter/material.dart';
import 'package:money_note/components/forms/date_filter_dropdown.dart';
import 'package:money_note/constants/date_filter_option.dart';
import 'package:money_note/components/forms/display_option_selector.dart';

class ReportFilter extends StatefulWidget implements PreferredSizeWidget {
  final DateFilterOption? selectedRange;
  final String groupBy;
  final void Function(
    DateFilterOption option, {
    DateTime? from,
    DateTime? to,
    String? label,
  })
  onDateRangePicked;
  final Function(String) onGroupChanged;

  const ReportFilter({
    super.key,
    this.selectedRange,
    required this.groupBy,
    required this.onDateRangePicked,
    required this.onGroupChanged,
  });

  @override
  State<ReportFilter> createState() => _ReportFilterState();

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class _ReportFilterState extends State<ReportFilter> {
  DateFilterOption _selectedDateFilter = DateFilterOption.thisMonth;
  String? _selectedLabel;
  late String _selectedGroupBy;

  void _applyDateFilter(
    DateFilterOption option, {
    DateTime? from,
    DateTime? to,
    String? label,
  }) {
    setState(() {
      _selectedDateFilter = option;
      _selectedLabel = label;
    });
    widget.onDateRangePicked(option, from: from, to: to, label: label);
  }

  void _applyGroupBy(String group) {
    setState(() {
      _selectedGroupBy = group;
    });
    widget.onGroupChanged(group);
  }

  @override
  void initState() {
    super.initState();
    _selectedGroupBy = widget.groupBy;
  }

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: DisplayOptionSelector(
                  groupBy: _selectedGroupBy,
                  onSelected: _applyGroupBy,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Date Filter
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: DateFilterDropdown(
                  selected: widget.selectedRange ?? _selectedDateFilter,
                  label: _selectedLabel,
                  onFilterApplied: _applyDateFilter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
