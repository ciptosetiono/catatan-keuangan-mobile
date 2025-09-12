class ReportItem {
  final DateTime date;
  final String title;
  final String type;
  final String wallet;
  final String? category;
  final double amount;

  ReportItem({
    required this.date,
    required this.title,
    required this.type,
    required this.wallet,
    this.category,
    required this.amount,
  });
}
