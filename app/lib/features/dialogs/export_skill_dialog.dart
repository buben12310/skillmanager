// Skill 导出对话框:选择导出到文件夹 / 导出到其他 Agent
// 使用 ConsumerStatefulWidget 内部切换状态,避免 pop 后 context 失效问题
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../core/path_expander.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/dialog_base.dart';
import '../../shared/widgets/toast.dart';

class ExportSkillDialog extends ConsumerStatefulWidget {
  const ExportSkillDialog({super.key, required this.sourceAgent, required this.skill});
  final Agent sourceAgent;
  final Skill skill;

  @override
  ConsumerState<ExportSkillDialog> createState() => _ExportSkillDialogState();
}

class _ExportSkillDialogState extends ConsumerState<ExportSkillDialog> {
  bool _showAgentSelector = false;
  List<Agent> _others = const [];
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final skill = widget.skill;
    if (_showAgentSelector) {
      return DialogBase(
        title: '选择目标 Agent',
        child: _others.isEmpty
            ? Text('没有其他 Agent 可选', style: AppTextStyles.body)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: _others
                    .map((a) => Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: _AgentTile(
                            agent: a,
                            onTap: _exporting ? null : () => _doExport(a),
                          ),
                        ))
                    .toList(),
              ),
      );
    }
    return DialogBase(
      title: '导出 Skill: ${skill.name}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Option(
            icon: Icons.folder_outlined,
            title: '导出到文件夹',
            subtitle: '将 skill 完整复制到指定位置',
            onTap: () => _exportToFolder(context, ref),
          ),
          const SizedBox(height: 8),
          _Option(
            icon: Icons.swap_horiz,
            title: '导出至其他 Agent',
            subtitle: '将 skill 复制并注册到另一个 Agent',
            onTap: _showAgents,
          ),
        ],
      ),
    );
  }

  /// 显示 Agent 选择列表 (内部 setState 切换,不 pop)
  Future<void> _showAgents() async {
    try {
      final agents = await ref.read(agentRepositoryProvider).list();
      final others = agents.where((a) => a.id != widget.sourceAgent.id).toList();
      if (!mounted) return;
      setState(() {
        _others = others;
        _showAgentSelector = true;
      });
      if (others.isEmpty) {
        showToast(context, '没有其他 Agent 可选');
      }
    } catch (e) {
      if (!mounted) return;
      showToast(context, '加载 Agent 列表失败: $e');
    }
  }

  /// 执行导出到目标 Agent
  Future<void> _doExport(Agent target) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await ref.read(skillRepositoryProvider).exportToAgent(
            widget.sourceAgent.id,
            widget.skill.id,
            target.id,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showToast(context, '已导出到 ${target.name}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      showToast(context, '导出失败: $e');
    }
  }

  Future<void> _exportToFolder(BuildContext context, WidgetRef ref) async {
    final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: '选择导出目录');
    if (dir == null) return;
    try {
      final srcPath = PathExpander.expand(widget.skill.path);
      final src = Directory(srcPath);
      final srcFile = File(srcPath);
      final dst = Directory(p.join(dir, widget.skill.name));

      // 清理已存在的目标
      if (await dst.exists()) {
        await dst.delete(recursive: true);
      }

      if (await src.exists()) {
        // 源是目录: 完整递归复制
        await _copyDir(src, dst);
      } else if (await srcFile.exists()) {
        // 源是单个文件 (如 SKILL.md): 复制到目标目录
        await dst.create(recursive: true);
        await srcFile.copy(p.join(dst.path, p.basename(srcPath)));
      } else {
        // 路径不存在,提示用户
        if (!context.mounted) return;
        showToast(context, '源路径不存在: $srcPath');
        return;
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
      showToast(context, '已导出到 ${dst.path}');
    } catch (e) {
      if (!context.mounted) return;
      showToast(context, '导出失败: $e');
    }
  }

  Future<void> _copyDir(Directory src, Directory dst) async {
    await dst.create(recursive: true);
    await for (final e in src.list()) {
      final newPath = p.join(dst.path, p.basename(e.path));
      if (e is File) {
        await e.copy(newPath);
      } else if (e is Directory) {
        await _copyDir(e, Directory(newPath));
      }
    }
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(width: 0.5, color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
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

class _AgentTile extends StatelessWidget {
  const _AgentTile({required this.agent, required this.onTap});
  final Agent agent;
  final VoidCallback? onTap;

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
