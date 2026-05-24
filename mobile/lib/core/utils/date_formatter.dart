import 'package:intl/intl.dart';

class DateFormatter {
  static String display(DateTime date) => DateFormat('d MMM, y').format(date);
  static String api(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
}
