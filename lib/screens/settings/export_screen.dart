import 'package:flutter/widgets.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreen();
}

class _ExportScreen extends State<ExportScreen> {
  DateTime? _from;
  DateTime? _to;
  // String? _wallet;
  //String? _type;
  //String? _category;

  @override
  Widget build(BuildContext context) {
    // Example usage of _from field
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _from != null
                ? 'From date: ${_from!.toLocal()}'
                : 'No from date selected',
          ),
          SizedBox(height: 8),
          Text(
            _to != null ? 'To date: ${_to!.toLocal()}' : 'No to date selected',
          ),
        ],
      ),
    );
  }
}
