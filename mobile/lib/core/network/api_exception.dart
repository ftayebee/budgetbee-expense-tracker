class ApiException implements Exception {
  ApiException(this.message, {this.errors = const {}, this.statusCode});

  final String message;
  final Map<String, dynamic> errors;
  final int? statusCode;

  @override
  String toString() => message;
}
