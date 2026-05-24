import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );
  static const section = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );
  static const body = TextStyle(fontSize: 14, color: AppColors.text);
  static const muted = TextStyle(fontSize: 13, color: AppColors.muted);
}
