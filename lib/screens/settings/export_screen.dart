import 'package:flutter/widgets.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreen();
}

class _ExportScreen extends State<ExportScreen> {
  DateTime? _from;
  DateTime? _to;
  String? _wallet;
  String? _type;
  String? _category;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
