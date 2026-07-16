import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../routes/app_routes.dart';
import '../config/app_links.dart';

class AppActions {
  AppActions._();

  static Future<void> rateApp(BuildContext context) async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
        return;
      }
      final configuredUrl = Platform.isIOS
          ? AppLinks.appStoreUrl
          : AppLinks.playStoreUrl;
      if (configuredUrl.isNotEmpty && await _launchHttps(configuredUrl)) return;
      if (context.mounted) {
        _message(context, 'BudgetBee is not yet available in the app store.');
      }
    } catch (_) {
      if (context.mounted) {
        _message(context, 'The app store could not be opened right now.');
      }
    }
  }

  static Future<void> openPrivacyPolicy(BuildContext context) async {
    if (AppLinks.privacyPolicyUrl.isNotEmpty) {
      if (await _launchHttps(AppLinks.privacyPolicyUrl)) return;
      if (context.mounted) {
        _message(context, 'The privacy policy link could not be opened.');
      }
      return;
    }
    if (context.mounted) Navigator.pushNamed(context, AppRoutes.privacyPolicy);
  }

  static Future<void> contactSupport(BuildContext context) async {
    if (AppLinks.supportEmail.isEmpty) {
      _message(context, 'Support contact has not been configured yet.');
      return;
    }
    final uri = Uri(
      scheme: 'mailto',
      path: AppLinks.supportEmail,
      queryParameters: {'subject': 'BudgetBee Support'},
    );
    if (!await launchUrl(uri) && context.mounted) {
      _message(context, 'No email application is available.');
    }
  }

  static Future<bool> _launchHttps(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
