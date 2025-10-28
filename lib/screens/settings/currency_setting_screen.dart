import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_note/services/setting_preferences_service.dart';
import 'package:money_note/models/currency_setting_model.dart';

class SettingCurrencyScreen extends StatefulWidget {
  const SettingCurrencyScreen({super.key});

  @override
  State<SettingCurrencyScreen> createState() => _SettingCurrencyScreenState();
}

class _SettingCurrencyScreenState extends State<SettingCurrencyScreen> {
  final _prefs = SettingPreferencesService();
  CurrencySetting? _currentSetting;
  String? _selectedCode;
  bool _showSymbol = true;
  bool _showDecimal = true;

  final _currencies = const [
    {
      'code': 'IDR',
      'symbol': 'Rp',
      'locale': 'id_ID',
      'name': 'Indonesian Rupiah',
    },
    {'code': 'USD', 'symbol': '\$', 'locale': 'en_US', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'locale': 'en_EU', 'name': 'Euro'},
    {'code': 'JPY', 'symbol': '¥', 'locale': 'ja_JP', 'name': 'Japanese Yen'},
    {'code': 'GBP', 'symbol': '£', 'locale': 'en_GB', 'name': 'British Pound'},
    {
      'code': 'SGD',
      'symbol': '\$',
      'locale': 'en_SG',
      'name': 'Singapore Dollar',
    },
    {
      'code': 'AUD',
      'symbol': '\$',
      'locale': 'en_AU',
      'name': 'Australian Dollar',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrencySetting();
  }

  Future<void> _loadCurrencySetting() async {
    final setting = await _prefs.getCurrencySetting();
    setState(() {
      _currentSetting = setting;
      _selectedCode = setting.currencyCode;
      _showSymbol = setting.showSymbol ?? true;
      _showDecimal = setting.showDecimal ?? true;
    });
  }

  Future<void> _saveCurrencySetting() async {
    final selected = _currencies.firstWhere((c) => c['code'] == _selectedCode);

    final setting = CurrencySetting(
      currencyCode: selected['code']!,
      symbol: selected['symbol']!,
      locale: selected['locale']!,
      showSymbol: _showSymbol,
      showDecimal: _showDecimal,
    );

    await _prefs.setCurrencySetting(setting);
    setState(() => _currentSetting = setting);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Currency settings saved: ${setting.currencyCode}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatExample(String locale, String symbol) {
    try {
      final format = NumberFormat.currency(
        locale: locale,
        symbol: _showSymbol ? symbol : '',
        decimalDigits: _showDecimal ? 2 : 0,
      );
      return format.format(1234567.89);
    } catch (_) {
      return '${_showSymbol ? symbol : ''} 1,234,567';
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCode =
        _selectedCode ?? _currentSetting?.currencyCode ?? 'USD';
    final selected = _currencies.firstWhere((c) => c['code'] == selectedCode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Setting'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body:
          _currentSetting == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // === REAL-TIME PREVIEW ===
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    color: Colors.lightBlue.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Preview',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatExample(
                            selected['locale']!,
                            selected['symbol']!,
                          ),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // === CURRENCY LIST ===
                  Expanded(
                    child: ListView.builder(
                      itemCount: _currencies.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final c = _currencies[index];
                        final isSelected = c['code'] == selectedCode;
                        final exampleText = _formatExample(
                          c['locale']!,
                          c['symbol']!,
                        );

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? Colors.lightBlue
                                      : Colors.grey.shade300,
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              '${c['symbol']}  ${c['name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${c['code']}  •  Example: $exampleText',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color:
                                  isSelected ? Colors.lightBlue : Colors.grey,
                            ),
                            onTap:
                                () => setState(() => _selectedCode = c['code']),
                          ),
                        );
                      },
                    ),
                  ),

                  // === OPTIONS SECTION ===
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Display Options',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Show Currency Symbol'),
                          value: _showSymbol,
                          onChanged: (val) => setState(() => _showSymbol = val),
                          dense: true,
                        ),
                        SwitchListTile(
                          title: const Text('Show Decimal Digits'),
                          value: _showDecimal,
                          onChanged:
                              (val) => setState(() => _showDecimal = val),
                          dense: true,
                        ),
                      ],
                    ),
                  ),

                  // === SAVE BUTTON ===
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          _selectedCode == null ? null : _saveCurrencySetting,
                      //icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
    );
  }
}
