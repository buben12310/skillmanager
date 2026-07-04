// 对照 DESIGN_SPEC §6.1 色彩规范
import 'package:flutter/material.dart';

/// 全局可变调色板。主题/强调色切换时通过 [applyAccent] / [applyBrightness] 更新。
class AppColors {
  AppColors._();

  // === 强调色 (mutable) ===
  static Color _primary = Color(0xFF534AB7);
  static Color _primaryLight = Color(0xFFEEEDFE);
  static Color get primary => _primary;
  static Color get primaryLight => _primaryLight;
  static void applyAccent(Color c) {
    _primary = c;
    _primaryLight = Color.lerp(c, Colors.white, 0.85)!;
  }

  // === 状态色 (固定) ===
  static const Color success = Color(0xFF639922);
  static const Color successLight = Color(0xFFEAF3DE);
  static const Color warning = Color(0xFFEF9F27);
  static const Color warningLight = Color(0xFFFAEEDA);
  static const Color danger = Color(0xFFE24B4A);
  static const Color dangerLight = Color(0xFFFCEBEB);

  // === 背景与文字 (mutable, 主题切换时变化) ===
  static Color _bgPrimary = Color(0xFFFFFFFF);
  static Color _bgSecondary = Color(0xFFF1EFE8);
  static Color _border = Color(0x26000000);
  static Color _textPrimary = Color(0xFF2C2C2A);
  static Color _textSecondary = Color(0xFF5F5E5A);
  static Color _textTertiary = Color(0xFF888780);

  static Color get bgPrimary => _bgPrimary;
  static Color get bgSecondary => _bgSecondary;
  static Color get border => _border;
  static Color get textPrimary => _textPrimary;
  static Color get textSecondary => _textSecondary;
  static Color get textTertiary => _textTertiary;

  static bool _isDark = false;
  static bool get isDark => _isDark;

  static void applyBrightness(Brightness b) {
    _isDark = b == Brightness.dark;
    if (_isDark) {
      _bgPrimary = Color(0xFF1A1A1A);
      _bgSecondary = Color(0xFF252525);
      _border = Color(0x40FFFFFF);
      _textPrimary = Color(0xFFE8E8E8);
      _textSecondary = Color(0xFFB8B8B8);
      _textTertiary = Color(0xFF808080);
    } else {
      _bgPrimary = Color(0xFFFFFFFF);
      _bgSecondary = Color(0xFFF1EFE8);
      _border = Color(0x26000000);
      _textPrimary = Color(0xFF2C2C2A);
      _textSecondary = Color(0xFF5F5E5A);
      _textTertiary = Color(0xFF888780);
    }
  }

  // === 类型标 (固定) ===
  static const Color skillBadgeBg = Color(0xFFE1F5EE);
  static const Color skillBadgeText = Color(0xFF0F6E56);
  static const Color mcpBadgeBg = Color(0xFFE6F1FB);
  static const Color mcpBadgeText = Color(0xFF185FA5);

  // === Agent 图标底色 (固定) ===
  static const Color agentClaude = Color(0xFF534AB7);
  static const Color agentCodex = Color(0xFF185FA5);
  static const Color agentOpenCode = Color(0xFF0F6E56);
  static const Color agentHermes = Color(0xFFE24B4A);

  // === 内置强调色选项 ===
  static const List<Color> accentPresets = [
    Color(0xFF534AB7), // 紫
    Color(0xFF185FA5), // 蓝
    Color(0xFF639922), // 绿
    Color(0xFFE24B4A), // 红
    Color(0xFFEF9F27), // 橙
  ];
}
