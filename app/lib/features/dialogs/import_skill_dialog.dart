// 导入 Skill 对话框:支持从其他 Agent 导入 / 从 .skillpack (zip) 文件导入
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../core/path_expander.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/models.dart';
import '../../data/repositories/skill_repository.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/dialog_base.dart';
import '../../shared/widgets/toast.dart';
import 'agent_selector_dialog.dart';

class ImportSkillDialog extends ConsumerStatefulWidget {
  const ImportSkillDialog({super.key, required this.targetAgent, this.onComplete});
  final Agent targetAgent;
  final VoidCallback? onComplete;

  @override
  ConsumerState<ImportSkillDialog> createState() => _ImportSkillDialogState();
}

class _ImportSkillDialogState extends ConsumerState<ImportSkillDialog> {
  _ImportMode _mode = _ImportMode.otherAgent;

  // 从其他 Agent 导入的状态
  Agent? _sourceAgent;
  Skill? _sourceSkill;

  @override
  Widget build(BuildContext context) {
    return DialogBase(
      title: '导入 Skill 到 ${widget.targetAgent.name}',
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 模式选择
            _buildModeSelector(),
            const SizedBox(height: 16),
            // 内容区
            if (_mode == _ImportMode.otherAgent)
              _buildOtherAgentSection()
            else
              _buildSkillpackSection(),
            const SizedBox(height: 16),
            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text('取消', style: AppTextStyles.body),
                ),
                const SizedBox(width: 8),
                PrimaryButton(
                  label: '导入',
                  icon: Icons.download,
                  onPressed: _canImport ? _doImport : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        _modeTab(_ImportMode.otherAgent, '从其他 Agent', Icons.swap_horiz),
        const SizedBox(width: 8),
        _modeTab(_ImportMode.skillpackFile, '从 .skillpack 文件', Icons.file_upload_outlined),
      ],
    );
  }

  Widget _modeTab(_ImportMode mode, String label, IconData icon) {
    final selected = _mode == mode;
    return InkWell(
      onTap: () => setState(() => _mode = mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.body.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherAgentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('来源 Agent', style: AppTextStyles.secondary),
        const SizedBox(height: 8),
        if (_sourceAgent == null)
          SecondaryButton(
            label: '选择来源 Agent',
            icon: Icons.folder_open,
            onPressed: _selectSourceAgent,
          )
        else
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _sourceAgent!.iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_sourceAgent!.icon, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _sourceAgent!.iconColor)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(_sourceAgent!.name, style: AppTextStyles.listItemPrimary)),
              TextButtonX(label: '更换', icon: Icons.swap_horiz, onPressed: _selectSourceAgent),
            ],
          ),
        if (_sourceAgent != null) ...[
          const SizedBox(height: 12),
          Text('选择 Skill', style: AppTextStyles.secondary),
          const SizedBox(height: 8),
          FutureBuilder<List<Skill>>(
            future: ref.read(skillRepositoryProvider).listByAgent(_sourceAgent!.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
              }
              final skills = snapshot.data!;
              if (skills.isEmpty) {
                return Text('该 Agent 没有可导入的 Skill', style: AppTextStyles.secondary);
              }
              return Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(width: 0.5, color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: skills.length,
                  itemBuilder: (context, i) {
                    final s = skills[i];
                    final selected = _sourceSkill?.id == s.id;
                    return InkWell(
                      onTap: () => setState(() => _sourceSkill = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                          border: Border(bottom: BorderSide(width: 0.5, color: AppColors.border)),
                        ),
                        child: Row(
                          children: [
                            Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                                size: 14, color: selected ? AppColors.primary : AppColors.textTertiary),
                            const SizedBox(width: 8),
                            Expanded(child: Text(s.name, style: AppTextStyles.body)),
                            if (s.version != null)
                              Text(s.version!, style: AppTextStyles.secondary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSkillpackSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(child: Text('选择 .skillpack (zip) 文件,解压后导入到 ${widget.targetAgent.name} 的 skill 目录', style: AppTextStyles.secondary)),
            ],
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: '选择文件',
            icon: Icons.file_open,
            onPressed: _selectSkillpackFile,
          ),
        ],
      ),
    );
  }

  Future<void> _selectSourceAgent() async {
    final agents = await ref.read(agentRepositoryProvider).list();
    final others = agents.where((a) => a.id != widget.targetAgent.id).toList();
    if (!mounted) return;
    if (others.isEmpty) {
      showToast(context, '没有其他 Agent 可选');
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AgentSelectorDialog(
        agents: others,
        onSelect: (agent) => setState(() {
          _sourceAgent = agent;
          _sourceSkill = null;
        }),
      ),
    );
  }

  String? _skillpackPath;

  Future<void> _selectSkillpackFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择 .skillpack 文件',
      type: FileType.custom,
      allowedExtensions: ['zip', 'skillpack'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _skillpackPath = result.files.first.path);
      if (!mounted) return;
      showToast(context, '已选择: ${result.files.first.name}');
    }
  }

  bool get _canImport {
    if (_mode == _ImportMode.otherAgent) {
      return _sourceAgent != null && _sourceSkill != null;
    }
    return _skillpackPath != null;
  }

  Future<void> _doImport() async {
    try {
      if (_mode == _ImportMode.otherAgent) {
        await _importFromAgent();
      } else {
        await _importFromSkillpack();
      }
      widget.onComplete?.call();
    } catch (e) {
      if (!mounted) return;
      showToast(context, '导入失败: $e');
    }
  }

  /// 从其他 Agent 导入:复制 skill 文件 + 注册数据库
  Future<void> _importFromAgent() async {
    final skill = _sourceSkill!;
    final srcPath = PathExpander.expand(skill.path);
    final dstBase = PathExpander.expand(widget.targetAgent.skillPath);
    final dstPath = p.join(dstBase, skill.name);

    // 确保目标目录存在
    await Directory(dstBase).create(recursive: true);

    // 复制文件
    final srcDir = Directory(srcPath);
    final srcFile = File(srcPath);
    if (await srcDir.exists()) {
      final dstDir = Directory(dstPath);
      if (await dstDir.exists()) {
        await dstDir.delete(recursive: true);
      }
      await _copyDir(srcDir, dstDir);
    } else if (await srcFile.exists()) {
      await Directory(dstPath).create(recursive: true);
      await srcFile.copy(p.join(dstPath, p.basename(srcPath)));
    }

    // 注册到数据库
    await ref.read(skillRepositoryProvider).add(
          widget.targetAgent.id,
          AddSkillRequest(
            name: skill.name,
            path: p.join(widget.targetAgent.skillPath, skill.name, ''),
            format: widget.targetAgent.format,
          ),
        );

    if (!mounted) return;
    Navigator.of(context).maybePop();
    showToast(context, '已导入 ${skill.name}');
  }

  /// 从 .skillpack (zip) 文件导入:解压 + 注册数据库
  Future<void> _importFromSkillpack() async {
    final zipPath = _skillpackPath!;
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // 解压到目标 agent 的 skill 目录下的临时子目录
    final dstBase = PathExpander.expand(widget.targetAgent.skillPath);
    await Directory(dstBase).create(recursive: true);

    // 解压并找出 skill 名称 (通常是 zip 根目录名或 SKILL.md 所在目录)
    String? skillName;
    for (final file in archive) {
      final filename = file.name;
      if (filename.endsWith('SKILL.md') || filename.endsWith('skill.md')) {
        // 提取所在目录名作为 skill 名称
        final parts = filename.split('/').where((s) => s.isNotEmpty).toList();
        if (parts.length > 1) {
          skillName = parts[parts.length - 2];
        }
        break;
      }
    }
    skillName ??= p.basenameWithoutExtension(zipPath).replaceAll('.skillpack', '');

    final dstPath = p.join(dstBase, skillName);
    final dstDir = Directory(dstPath);
    if (await dstDir.exists()) {
      await dstDir.delete(recursive: true);
    }
    await dstDir.create(recursive: true);

    // 解压文件
    for (final file in archive) {
      if (file.isFile) {
        final outPath = p.join(dstPath, file.name);
        await File(outPath).parent.create(recursive: true);
        await File(outPath).writeAsBytes(file.content as List<int>);
      }
    }

    // 注册到数据库
    await ref.read(skillRepositoryProvider).add(
          widget.targetAgent.id,
          AddSkillRequest(
            name: skillName,
            path: p.join(widget.targetAgent.skillPath, skillName, ''),
            format: widget.targetAgent.format,
          ),
        );

    if (!mounted) return;
    Navigator.of(context).maybePop();
    showToast(context, '已导入 $skillName');
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

enum _ImportMode { otherAgent, skillpackFile }
