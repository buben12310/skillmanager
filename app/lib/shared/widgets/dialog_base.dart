// 通用对话框脚手架,统一最大宽度 / 间距
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class DialogBase extends StatelessWidget {
  const DialogBase({
    super.key,
    required this.title,
    required this.child,
    this.width = 480,
    this.padding = const EdgeInsets.all(20),
  });
  final String title;
  final Widget child;
  final double width;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgPrimary,
      insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  Text(title, style: AppTextStyles.pageTitle),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.close, size: 18, color: AppColors.textTertiary),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: AppColors.border),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
