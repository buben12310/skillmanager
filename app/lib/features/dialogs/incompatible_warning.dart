// 对照 DESIGN_SPEC §4.4 格式不兼容警告
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/dialog_base.dart';

class IncompatibleWarning extends StatelessWidget {
  const IncompatibleWarning({
    super.key,
    required this.skillName,
    required this.skillFormat,
    required this.agentName,
    required this.agentFormat,
    required this.onForceInstall,
  });

  final String skillName;
  final String skillFormat;
  final String agentName;
  final String agentFormat;
  final VoidCallback onForceInstall;

  @override
  Widget build(BuildContext context) {
    return DialogBase(
      title: '格式不兼容',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(width: 0.5, color: AppColors.warning),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '技能 「$skillName」的格式 ($skillFormat) 与 Agent「$agentName」的格式 ($agentFormat) 不兼容,'
                    '强行安装可能无法正常工作。',
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SecondaryButton(label: '取消', onPressed: () => Navigator.of(context).maybePop()),
              SizedBox(width: 8),
              DangerButton(label: '强行安装', onPressed: () {
                Navigator.of(context).maybePop();
                onForceInstall();
              }),
            ],
          ),
        ],
      ),
    );
  }
}
