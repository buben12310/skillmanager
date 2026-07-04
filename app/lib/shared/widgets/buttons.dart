// 对照 DESIGN_SPEC §7.2 按钮规范
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expanded ? double.infinity : null,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
        ),
        child: icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16),
                  SizedBox(width: 6),
                  Text(label),
                ],
              ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: BorderSide(width: 0.5, color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: AppTextStyles.body,
      ),
      child: icon == null
          ? Text(label)
          : Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16), SizedBox(width: 6), Text(label)]),
    );
  }
}

class DashedButton extends StatelessWidget {
  const DashedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expanded ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(width: 0.5, color: AppColors.primary, style: BorderStyle.solid),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: AppTextStyles.body.copyWith(color: AppColors.primary),
        ),
        child: icon == null
            ? Text(label)
            : Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16), SizedBox(width: 6), Text(label)]),
      ),
    );
  }
}

class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.danger,
        side: const BorderSide(width: 0.5, color: AppColors.danger),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: AppTextStyles.body.copyWith(color: AppColors.danger),
      ),
      child: Text(label),
    );
  }
}

class TextButtonX extends StatelessWidget {
  const TextButtonX({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppColors.primary,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        textStyle: AppTextStyles.body,
      ),
      child: icon == null
          ? Text(label)
          : Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14), SizedBox(width: 4), Text(label)]),
    );
  }
}
