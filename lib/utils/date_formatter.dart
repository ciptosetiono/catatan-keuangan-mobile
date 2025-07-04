import 'package:intl/intl.dart';

class DateFormatter {
  String formatMonth(DateTime date) {
    return DateFormat.yMMMM().format(date);
  }
}
