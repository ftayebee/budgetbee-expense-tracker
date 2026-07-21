class ApiConstants {
  static const String _defaultBaseUrl =
      'https://budgetbee.crowdzonebd.com/api/v1';
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  static final String baseUrl = _normalize(_configuredBaseUrl);

  static String _normalize(String value) {
    final candidate = value.trim().isEmpty ? _defaultBaseUrl : value.trim();
    final normalized = candidate.replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return normalized;
    }
    return normalized;
  }

  static bool get hasValidBaseUrl {
    final uri = Uri.tryParse(baseUrl);
    return uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }
}
