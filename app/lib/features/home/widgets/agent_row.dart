import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/badges.dart';

class AgentRow extends StatelessWidget {
  const AgentRow({
    super.key,
    required this.agent,
    required this.skillCount,
    required this.mcpCount,
    required this.onTap,
  });
  final Agent agent;
  final int skillCount;
  final int mcpCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unconfigured = agent.status == AgentStatus.unconfigured;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(width: 0.5, color: AppColors.border),
          ),
        ),
        child: Row(
          children: [
            _AgentIcon(agent: agent),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(agent.name, style: AppTextStyles.listItemPrimary),
                  SizedBox(height: 2),
                  Text(
                    unconfigured ? '未安装' : agent.skillPath,
                    style: AppTextStyles.code.copyWith(
                      color: unconfigured ? AppColors.textTertiary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _CountCell(value: unconfigured ? '-' : skillCount.toString()),
            _CountCell(value: unconfigured ? '-' : mcpCount.toString()),
            SizedBox(width: 8),
            StatusDot(active: !unconfigured),
            SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _AgentIcon extends StatelessWidget {
  const _AgentIcon({required this.agent});
  final Agent agent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: agent.iconColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        agent.icon,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: agent.iconColor,
        ),
      ),
    );
  }
}

class _CountCell extends StatelessWidget {
  const _CountCell({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Text(value, style: AppTextStyles.body, textAlign: TextAlign.center),
    );
  }
}
