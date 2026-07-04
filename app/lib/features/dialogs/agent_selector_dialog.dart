// 对照 DESIGN_SPEC §4.3 选择目标 Agent
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/dialog_base.dart';

class AgentSelectorDialog extends StatelessWidget {
  const AgentSelectorDialog({super.key, required this.agents, required this.onSelect});
  final List<Agent> agents;
  final void Function(Agent) onSelect;

  @override
  Widget build(BuildContext context) {
    return DialogBase(
      title: '选择目标 Agent',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: agents
            .map((a) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: _AgentTile(
                    agent: a,
                    onTap: () {
                      Navigator.of(context).maybePop();
                      onSelect(a);
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _AgentTile extends StatelessWidget {
  const _AgentTile({required this.agent, required this.onTap});
  final Agent agent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unconfigured = agent.status == AgentStatus.unconfigured;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(width: 0.5, color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: agent.iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(agent.icon, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: agent.iconColor)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(agent.name, style: AppTextStyles.listItemPrimary),
                  Text(unconfigured ? '未配置' : agent.format.label, style: AppTextStyles.secondary),
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
