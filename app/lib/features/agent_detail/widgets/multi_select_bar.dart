// 对照 DESIGN_SPEC §3.2 多选栏
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons.dart';

class MultiSelectBar extends StatelessWidget {
  const MultiSelectBar({
    super.key,
    required this.selectedCount,
    required this.onExport,
    required this.onDelete,
    required this.onCancel,
  });

  final int selectedCount;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        border: Border(top: BorderSide(width: 0.5, color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text('已选 $selectedCount 项', style: AppTextStyles.listItemPrimary.copyWith(color: AppColors.primary)),
          Spacer(),
          SecondaryButton(label: '批量导出', icon: Icons.download, onPressed: onExport),
          SizedBox(width: 8),
          DangerButton(label: '批量删除', onPressed: onDelete),
          SizedBox(width: 8),
          TextButtonX(label: '取消', color: AppColors.textSecondary, onPressed: onCancel),
        ],
      ),
    );
  }
}
