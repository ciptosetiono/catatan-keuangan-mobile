class CurrencySetting {
  final String currencyCode;
  final String symbol;
  final String locale;
  final bool? showSymbol;
  final bool? showDecimal;

  CurrencySetting({
    required this.currencyCode,
    required this.symbol,
    required this.locale,
    this.showSymbol,
    this.showDecimal,
  });

  Map<String, dynamic> toMap() {
    return {
      'currencyCode': currencyCode,
      'symbol': symbol,
      'locale': locale,
      'showSymbol': showSymbol,
      'showDecimal': showDecimal,
    };
  }

  factory CurrencySetting.fromMap(Map<String, dynamic> map) {
    return CurrencySetting(
      currencyCode: map['currencyCode'] ?? 'USD',
      symbol: map['symbol'] ?? '',
      locale: map['locale'] ?? 'en_US',
      showSymbol: map['showSymbol'] ?? true,
      showDecimal: map['showDecimal'] ?? true,
    );
  }
}
