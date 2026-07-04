import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../features/agent_detail/agent_detail_page.dart';
import '../../features/dialogs/new_agent_dialog.dart';
import '../../features/home/home_page.dart';
import '../../features/marketplace/marketplace_page.dart';
import '../../features/mcp_detail/mcp_detail_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/skill_detail/skill_detail_page.dart';
import '../../shared/widgets/toast.dart';
import '../widgets/bottom_nav_bar.dart';
import 'detail_nav_state.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stack = ref.watch(detailStackProvider);
    final tab = ref.watch(currentNavTabProvider);

    Widget content;
    if (stack.isNotEmpty) {
      final top = stack.last;
      switch (top) {
        case AgentEntry(:final agent):
          content = AgentDetailPage(
            agent: agent,
            onBack: () => ref.read(detailStackProvider.notifier).pop(),
            onOpenSkill: (s) =>
                ref.read(detailStackProvider.notifier).pushSkill(agent, s),
            onOpenMcp: (m) =>
                ref.read(detailStackProvider.notifier).pushMcp(agent, m),
          );
        case SkillEntry(:final agent, :final skill):
          content = SkillDetailPage(
            agent: agent,
            skill: skill,
            onBack: () => ref.read(detailStackProvider.notifier).pop(),
          );
        case McpEntry(:final agent, :final mcp):
          content = McpDetailPage(
            agent: agent,
            mcp: mcp,
            onBack: () => ref.read(detailStackProvider.notifier).pop(),
          );
      }
    } else {
      switch (tab) {
        case NavTab.agents:
          content = HomePage(
            onOpenAgent: (a) =>
                ref.read(detailStackProvider.notifier).pushAgent(a),
            onNewAgent: () => _showNewAgentDialog(context, ref),
            onScan: () => _scan(context, ref),
          );
        case NavTab.marketplace:
          content = const MarketplacePage();
        case NavTab.settings:
          content = const SettingsPage();
      }
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(stack.isNotEmpty ? stack.length.toString() : tab.name),
          child: content,
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Future<void> _scan(BuildContext context, WidgetRef ref) async {
    showToast(context, '正在扫描系统...');
    try {
      final result = await ref.read(agentRepositoryProvider).scan();
      if (!context.mounted) return;
      final installed = result.where((d) => d.existing).length;
      showToast(context, '扫描完成: $installed/${result.length} 个 Agent 已安装');
    } catch (e) {
      if (!context.mounted) return;
      showToast(context, '扫描失败: $e');
    }
  }

  void _showNewAgentDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => NewAgentDialog(
        onConfirm: (req) async {
          try {
            await ref.read(agentRepositoryProvider).create(req);
            if (!context.mounted) return;
            showToast(context, '已创建 Agent: ${req.name}');
          } catch (e) {
            if (!context.mounted) return;
            showToast(context, '创建失败: $e');
          }
        },
      ),
    );
  }
}
