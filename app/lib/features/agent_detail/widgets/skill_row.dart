// 对照 DESIGN_SPEC §3.2 Skill 行
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/buttons.dart';

class SkillRow extends StatelessWidget {
  const SkillRow({
    super.key,
    required this.skill,
    required this.selected,
    required this.multiSelectMode,
    required this.onTap,
    required this.onLongPress,
    required this.onExport,
  });

  final Skill skill;
  final bool selected;
  final bool multiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(width: 0.5, color: AppColors.border)),
        ),
        child: Row(
          children: [
            if (multiSelectMode)
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  selected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 14,
                  color: selected ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
            TypeBadge(kind: TypeKind.skill),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(skill.name, style: AppTextStyles.listItemPrimary),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      if (skill.version != null)
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Text(skill.version!, style: AppTextStyles.secondary),
                        ),
                      Text(_sourceLabel(skill.source), style: AppTextStyles.secondary),
                    ],
                  ),
                ],
              ),
            ),
            TextButtonX(label: '导出', icon: Icons.download, onPressed: onExport),
          ],
        ),
      ),
    );
  }

  String _sourceLabel(SkillSource s) {
    switch (s) {
      case SkillSource.marketplace: return '技能市场';
      case SkillSource.local: return '本地';
      case SkillSource.builtin: return 'Builtin';
      case SkillSource.import: return '导入';
    }
  }
}
