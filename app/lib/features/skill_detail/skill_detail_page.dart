// 对照 DESIGN_SPEC §3.4 Skill 详情页
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/path_expander.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/toast.dart';
import '../dialogs/export_skill_dialog.dart';

class SkillDetailPage extends ConsumerWidget {
  const SkillDetailPage({
    super.key,
    required this.agent,
    required this.skill,
    required this.onBack,
  });
  final Agent agent;
  final Skill skill;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSection('基本信息', [
                  _InfoRow(label: '名称', value: skill.name),
                  _InfoRow(label: '版本', value: skill.version ?? '-'),
                  _InfoRow(label: '作者', value: skill.author ?? '-'),
                  _InfoRow(label: '来源', value: _sourceLabel(skill.source)),
                  _InfoRow(label: '路径', value: skill.path, mono: true),
                  _InfoRow(label: '格式', value: skill.format.label),
                ]),
                const SizedBox(height: 16),
                _buildSection('依赖', [
                  if (skill.dependencies.isEmpty)
                    Text('无', style: AppTextStyles.secondary)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: skill.dependencies.map((d) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.bgSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(d, style: AppTextStyles.code.copyWith(fontSize: 11)),
                        );
                      }).toList(),
                    ),
                ]),
                const SizedBox(height: 16),
                _buildSection('描述', [
                  Text(
                    '该技能为 ${skill.name}。由 ${skill.author ?? '未知'} 提供,'
                    '安装于 ${agent.name}。\n'
                    '路径: ${skill.path}',
                    style: AppTextStyles.body,
                  ),
                ]),
              ],
            ),
          ),
          _buildActionBar(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(bottom: BorderSide(width: 0.5, color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 16),
          const TypeBadge(kind: TypeKind.skill),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skill.name, style: AppTextStyles.pageTitle),
                Text('${agent.name} · v${skill.version ?? '0.0.0'}', style: AppTextStyles.secondary),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openDirectory(context),
            icon: Icon(Icons.folder_open, color: AppColors.textSecondary, size: 18),
            tooltip: '在资源管理器中打开',
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 12),
          SecondaryButton(label: '导出', icon: Icons.download, onPressed: () {
            showDialog(
              context: context,
              builder: (_) => ExportSkillDialog(sourceAgent: agent, skill: skill),
            );
          }),
        ],
      ),
    );
  }

  /// 在资源管理器中打开 skill 目录
  Future<void> _openDirectory(BuildContext context) async {
    final raw = skill.path;
    if (raw.isEmpty) {
      showToast(context, '路径未配置');
      return;
    }
    final expanded = PathExpander.expand(raw);
    try {
      // 如果是文件路径,打开其所在目录
      String target = expanded;
      if (FileSystemEntity.isFileSync(expanded)) {
        target = expanded.substring(0, expanded.lastIndexOf(RegExp(r'[/\\]')));
      }
      // 目录不存在则自动创建
      if (!Directory(target).existsSync()) {
        await Directory(target).create(recursive: true);
      }
      if (Platform.isWindows) {
        await Process.start('explorer', [target]);
      } else if (Platform.isMacOS) {
        await Process.start('open', [target]);
      } else {
        await Process.start('xdg-open', [target]);
      }
    } catch (e) {
      if (!context.mounted) return;
      showToast(context, '打开失败: $e');
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 0.5, color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.panelTitle),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(top: BorderSide(width: 0.5, color: AppColors.border)),
      ),
      child: Row(
        children: [
          SecondaryButton(label: '导出', icon: Icons.download, onPressed: () {
            showDialog(
              context: context,
              builder: (_) => ExportSkillDialog(sourceAgent: agent, skill: skill),
            );
          }),
          const Spacer(),
          DangerButton(label: '删除', onPressed: () {}),
        ],
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.mono = false});
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTextStyles.secondary),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: mono ? AppTextStyles.code : AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
