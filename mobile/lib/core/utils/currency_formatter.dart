import 'package:intl/intl.dart';

import '../settings/app_currency.dart';

class CurrencyFormatter {
  static String currentCode = 'BDT';

  static String format(num value, {String? currency}) {
    final selected = AppCurrency.byCode(currency ?? currentCode);
    return NumberFormat.currency(
      symbol: selected.symbol,
      decimalDigits: 0,
    ).format(value);
  }

  static String symbol([String? currency]) =>
      AppCurrency.byCode(currency ?? currentCode).symbol;
}
