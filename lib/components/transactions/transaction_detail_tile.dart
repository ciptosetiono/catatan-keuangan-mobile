import 'package:flutter/material.dart';

class TransactionDetailTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;

  const TransactionDetailTile({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
