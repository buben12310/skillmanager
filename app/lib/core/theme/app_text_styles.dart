// 对照 DESIGN_SPEC §6.2 字体规范
// 字体: Inter (SIL OFL 1.1) via google_fonts, CJK 回退到系统字体
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  /// Inter 基础样式,CJK 字符回退到 Noto Sans SC → 微软雅黑
  static TextStyle get _base => GoogleFonts.inter().copyWith(
        fontFamilyFallback: const ['Noto Sans SC', 'Microsoft YaHei', 'PingFang SC'],
      );

  static TextStyle get pageTitle => _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get panelTitle => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get listItemPrimary => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get secondary => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get micro => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
      );

  static TextStyle get code => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        fontFamily: 'monospace',
        color: AppColors.textSecondary,
      );
}
