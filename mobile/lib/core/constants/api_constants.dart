class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://c235-203-31-169-226.ngrok-free.app/api/v1',
  );
}
