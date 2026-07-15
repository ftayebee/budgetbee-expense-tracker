class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://budgetbee.crowdzonebd.com/api/v1',
  );
}
