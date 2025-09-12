import 'package:flutter/material.dart';

class NotFoundDataMessage extends StatelessWidget {
  final String message;
  const NotFoundDataMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey),
          SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
