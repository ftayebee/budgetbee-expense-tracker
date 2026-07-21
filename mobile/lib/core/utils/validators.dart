class Validators {
  static String? required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;
  static String? email(String? value) {
    if (required(value) != null) return required(value);
    final candidate = value!.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(candidate)
        ? null
        : 'Enter a valid email address';
  }

  static String? phone(String? value) {
    final candidate = value?.trim() ?? '';
    if (candidate.isEmpty) return null;
    return RegExp(r'^\+?[0-9][0-9\s().-]{6,30}$').hasMatch(candidate)
        ? null
        : 'Enter a valid phone number';
  }

  static String? password(String? value) {
    final requiredMessage = required(value);
    if (requiredMessage != null) return requiredMessage;
    return value!.length < 8 ? 'Password must be at least 8 characters' : null;
  }

  static String? amount(String? value) {
    final parsed = double.tryParse(value ?? '');
    return parsed == null || parsed < 0 ? 'Enter a valid amount' : null;
  }
}
