// 对照 DESIGN_SPEC §3.2 MCP 行 (类型标 M 蓝色)
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/buttons.dart';

class McpRow extends StatelessWidget {
  const McpRow({
    super.key,
    required this.mcp,
    required this.selected,
    required this.multiSelectMode,
    required this.onTap,
    required this.onLongPress,
    required this.onExport,
  });

  final Mcp mcp;
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
            TypeBadge(kind: TypeKind.mcp),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mcp.name, style: AppTextStyles.listItemPrimary),
                  SizedBox(height: 2),
                  Text('${mcp.command} ${mcp.args.join(' ')}', style: AppTextStyles.code, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            StatusBadge(
              label: mcp.connected ? '已连接' : '断开',
              tone: mcp.connected ? BadgeTone.normal : BadgeTone.error,
            ),
            SizedBox(width: 8),
            TextButtonX(label: '导出', icon: Icons.download, onPressed: onExport),
          ],
        ),
      ),
    );
  }
}
