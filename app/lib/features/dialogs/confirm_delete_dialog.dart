// 对照 DESIGN_SPEC §4.5 删除确认
import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/dialog_base.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });
  final String title;
  final String message;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return DialogBase(
      title: title,
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppTextStyles.body),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SecondaryButton(label: '取消', onPressed: () => Navigator.of(context).maybePop()),
              SizedBox(width: 8),
              DangerButton(label: '删除', onPressed: () {
                Navigator.of(context).maybePop();
                onConfirm();
              }),
            ],
          ),
        ],
      ),
    );
  }
}
