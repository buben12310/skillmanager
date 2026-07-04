// 对照 DESIGN_SPEC §4.2 导入来源选择
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/dialog_base.dart';

class ImportSourceDialog extends StatelessWidget {
  const ImportSourceDialog({super.key, required this.onSelect});
  final void Function(ImportSource source) onSelect;

  @override
  Widget build(BuildContext context) {
    return DialogBase(
      title: '导入来源',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SourceTile(
            icon: Icons.folder_open,
            title: '从其他 Agent 导入',
            subtitle: '选择本机已有的 Agent 作为来源',
            onTap: () {
              Navigator.of(context).maybePop();
              onSelect(ImportSource.otherAgent);
            },
          ),
          SizedBox(height: 8),
          _SourceTile(
            icon: Icons.file_upload_outlined,
            title: '从 .skillpack 文件导入',
            subtitle: '选择本地打包的 .skillpack 文件',
            onTap: () {
              Navigator.of(context).maybePop();
              onSelect(ImportSource.skillpackFile);
            },
          ),
        ],
      ),
    );
  }
}

enum ImportSource { otherAgent, skillpackFile }

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(width: 0.5, color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.listItemPrimary),
                  Text(subtitle, style: AppTextStyles.secondary),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
