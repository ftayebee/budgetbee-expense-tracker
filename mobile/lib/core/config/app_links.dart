class AppLinks {
  AppLinks._();

  static const androidPackageName = 'com.expensetrack.expense_tracker';
  static const iosAppStoreId = String.fromEnvironment(
    'BUDGETBEE_IOS_APP_STORE_ID',
  );
  static const playStoreUrl = String.fromEnvironment(
    'BUDGETBEE_PLAY_STORE_URL',
  );
  static const appStoreUrl = String.fromEnvironment('BUDGETBEE_APP_STORE_URL');
  static const privacyPolicyUrl = String.fromEnvironment(
    'BUDGETBEE_PRIVACY_POLICY_URL',
  );
  static const supportEmail = String.fromEnvironment('BUDGETBEE_SUPPORT_EMAIL');
  static const websiteUrl = String.fromEnvironment('BUDGETBEE_WEBSITE_URL');
}
