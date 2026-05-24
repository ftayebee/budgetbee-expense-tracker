class Validators {
  static String? required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;
  static String? email(String? value) {
    if (required(value) != null) return required(value);
    return value!.contains('@') ? null : 'Enter a valid email';
  }

  static String? amount(String? value) {
    final parsed = double.tryParse(value ?? '');
    return parsed == null || parsed <= 0 ? 'Enter a valid amount' : null;
  }
}
