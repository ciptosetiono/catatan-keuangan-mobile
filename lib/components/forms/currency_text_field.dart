import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  const CurrencyTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.validator,
    this.locale,
  }) : super(key: key);

  final String? locale;

  @override
  State<CurrencyTextField> createState() => _CurrencyTextFieldState();
}

class _CurrencyTextFieldState extends State<CurrencyTextField> {
  final formatter = NumberFormat.currency(
    //locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );
  String lastValue = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_formatCurrency);
  }

  void _formatCurrency() {
    final rawText = widget.controller.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (rawText == lastValue) return;

    final number = int.tryParse(rawText);
    if (number == null) return;

    final newText = formatter.format(number);
    lastValue = rawText;

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_formatCurrency);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        //prefixText: 'Rp ',
      ),
      validator: widget.validator,
    );
  }
}
