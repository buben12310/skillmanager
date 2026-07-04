import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  /// 浅色主题。调用前需确保 AppColors.applyBrightness(Brightness.light) 已执行。
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        surface: AppColors.bgPrimary,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.bgPrimary,
      textTheme: base.textTheme.copyWith(
        titleLarge: AppTextStyles.pageTitle,
        titleMedium: AppTextStyles.panelTitle,
        bodyLarge: AppTextStyles.listItemPrimary,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.secondary,
        labelSmall: AppTextStyles.micro,
      ),
      dividerTheme: DividerThemeData(
        thickness: 0.5,
        color: AppColors.border,
        space: 0.5,
      ),
    );
  }

  /// 深色主题。调用前需确保 AppColors.applyBrightness(Brightness.dark) 已执行。
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        surface: AppColors.bgPrimary,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.bgPrimary,
      textTheme: base.textTheme.copyWith(
        titleLarge: AppTextStyles.pageTitle,
        titleMedium: AppTextStyles.panelTitle,
        bodyLarge: AppTextStyles.listItemPrimary,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.secondary,
        labelSmall: AppTextStyles.micro,
      ),
      dividerTheme: DividerThemeData(
        thickness: 0.5,
        color: AppColors.border,
        space: 0.5,
      ),
    );
  }
}
