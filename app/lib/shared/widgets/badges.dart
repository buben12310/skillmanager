// 对照 DESIGN_SPEC §7.4 状态徽章 + 类型标 S/M
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum BadgeTone { normal, warning, error, neutral, info }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});
  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(tone);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: AppTextStyles.micro.copyWith(color: fg, fontWeight: FontWeight.w500)),
    );
  }

  (Color, Color) _colors(BadgeTone t) {
    switch (t) {
      case BadgeTone.normal:
        return (AppColors.successLight, Color(0xFF3B6D11));
      case BadgeTone.warning:
        return (AppColors.warningLight, Color(0xFF854F0B));
      case BadgeTone.error:
        return (AppColors.dangerLight, Color(0xFFA32D2D));
      case BadgeTone.neutral:
        return (AppColors.bgSecondary, AppColors.textSecondary);
      case BadgeTone.info:
        return (AppColors.mcpBadgeBg, AppColors.mcpBadgeText);
    }
  }
}

enum TypeKind { skill, mcp }

class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.kind, this.label});
  final TypeKind kind;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final bg = kind == TypeKind.skill ? AppColors.skillBadgeBg : AppColors.mcpBadgeBg;
    final fg = kind == TypeKind.skill ? AppColors.skillBadgeText : AppColors.mcpBadgeText;
    final text = label ?? (kind == TypeKind.skill ? 'S' : 'M');
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.success : AppColors.textTertiary,
        shape: BoxShape.circle,
      ),
    );
  }
}
