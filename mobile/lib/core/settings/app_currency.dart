class AppCurrency {
  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  final String code;
  final String symbol;
  final String name;

  static const supported = [
    AppCurrency(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
    AppCurrency(code: 'USD', symbol: r'$', name: 'US Dollar'),
    AppCurrency(code: 'EUR', symbol: '€', name: 'Euro'),
    AppCurrency(code: 'GBP', symbol: '£', name: 'British Pound'),
    AppCurrency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
  ];

  static AppCurrency byCode(String code) => supported.firstWhere(
    (currency) => currency.code == code,
    orElse: () => supported.first,
  );
}
