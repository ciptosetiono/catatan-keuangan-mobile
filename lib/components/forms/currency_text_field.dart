import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';
import '../../models/currency_setting_model.dart';
import '../../services/setting_preferences_service.dart';
import 'package:intl/intl.dart';

class CurrencyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? placeholder;
  final String? Function(String?)? validator;

  const CurrencyTextField({
    super.key,
    required this.controller,
    required this.label,
    this.placeholder,
    this.validator,
  });

  @override
  State<CurrencyTextField> createState() => _CurrencyTextFieldState();
}

class _CurrencyTextFieldState extends State<CurrencyTextField> {
  final SettingPreferencesService _prefs = SettingPreferencesService();
  // ignore: unused_field
  late CurrencyFormatter _currencyFormatter;
  CurrencySetting? _currencySetting;

  String lastValue = '';

  @override
  void initState() {
    super.initState();
    _currencyFormatter = CurrencyFormatter();
    _loadCurrencySetting();
    widget.controller.addListener(_formatCurrency);
  }

  Future<void> _loadCurrencySetting() async {
    final setting = await _prefs.getCurrencySetting();
    setState(() {
      _currencySetting = setting;
    });
  }

  void _formatCurrency() async {
    final rawText = widget.controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (rawText == lastValue || rawText.isEmpty) return;

    final number = int.tryParse(rawText);
    if (number == null) return;

    // use loaded setting or default
    final setting =
        _currencySetting ??
        CurrencySetting(currencyCode: '', symbol: '\$', locale: 'en_US');
    // Tentukan jumlah digit desimal
    final bool showSymbol = setting.showSymbol ?? true;
    final bool showDecimals = setting.showDecimal ?? true;

    final formatted = NumberFormat.currency(
      locale: setting.locale,
      symbol: showSymbol ? '${setting.symbol} ' : '',
      decimalDigits: showDecimals ? 2 : 0,
    ).format(number);

    lastValue = rawText;

    widget.controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_formatCurrency);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            //prefixText: '$currencySymbol ',
            hintText: widget.placeholder ?? 'Enter amount',
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
          validator: widget.validator,
        ),
      ],
    );
  }
}
