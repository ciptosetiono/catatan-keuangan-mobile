import 'package:flutter/material.dart';

class DisplayOptionSelector extends StatelessWidget {
  final String groupBy;
  final void Function(String)? onSelected;

  const DisplayOptionSelector({
    super.key,
    this.groupBy = "month",
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400), // optional border
      ),
      child: Row(
        children: [
          const Icon(Icons.stacked_bar_chart, color: Colors.black),
          const SizedBox(width: 8),

          // Group By Filter (expand like a dropdown)
          Expanded(
            child: PopupMenuButton<String>(
              initialValue: groupBy,
              onSelected: onSelected,
              constraints: const BoxConstraints(
                minWidth:
                    double.infinity, // force dropdown to match parent width
              ),
              itemBuilder: (context) => const [
                PopupMenuItem(value: "day", child: Text("By Day")),
                PopupMenuItem(value: "week", child: Text("By Week")),
                PopupMenuItem(value: "month", child: Text("By Month")),
                PopupMenuItem(value: "year", child: Text("By Year")),
              ],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(groupBy), const Icon(Icons.arrow_drop_down)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
