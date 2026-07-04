// 对照 DESIGN_SPEC §4.1 新建 Agent
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/models.dart';
import '../../data/repositories/agent_repository.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/dialog_base.dart';

class NewAgentDialog extends StatefulWidget {
  const NewAgentDialog({super.key, required this.onConfirm});
  final void Function(CreateAgentRequest) onConfirm;

  @override
  State<NewAgentDialog> createState() => _NewAgentDialogState();
}

class _NewAgentDialogState extends State<NewAgentDialog> {
  final _name = TextEditingController();
  final _skillPath = TextEditingController();
  final _mcpPath = TextEditingController();
  AgentFormat _format = AgentFormat.claudeCode;

  @override
  void dispose() {
    _name.dispose();
    _skillPath.dispose();
    _mcpPath.dispose();
    super.dispose();
  }

  Future<void> _pickDir(TextEditingController ctrl) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择目录',
    );
    if (result != null && mounted) {
      // 统一用正斜杠尾斜杠格式,便于跨平台
      final normalized = result.replaceAll('\\', '/');
      final withSlash = normalized.endsWith('/') ? normalized : '$normalized/';
      setState(() => ctrl.text = withSlash);
    }
  }

  void _confirm() {
    if (_name.text.trim().isEmpty) return;
    final req = CreateAgentRequest(
      name: _name.text.trim(),
      icon: _name.text.trim().substring(0, _name.text.trim().length.clamp(0, 2)).toUpperCase(),
      iconColor: _colorFor(_format),
      skillPath: _skillPath.text.trim(),
      mcpPath: _mcpPath.text.trim(),
      format: _format,
    );
    widget.onConfirm(req);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return DialogBase(
      title: '新建 Agent',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 模板列表 (扫描区)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: AppColors.textTertiary),
                SizedBox(width: 8),
                Text('从模板选择', style: AppTextStyles.secondary),
                SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    children: AgentFormat.values.map((f) {
                      final selected = _format == f;
                      return InkWell(
                        onTap: () => setState(() => _format = f),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : AppColors.bgPrimary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                          f.label,
                          style: AppTextStyles.micro.copyWith(color: selected ? Colors.white : AppColors.textSecondary),
                        ),
                      ),
                    );
                  }).toList(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          _Field(label: '名称 *', controller: _name, hint: 'Claude Code'),
          SizedBox(height: 12),
          _PathField(
            label: 'Skill 路径',
            controller: _skillPath,
            hint: '~/.claude/skills/',
            onPick: () => _pickDir(_skillPath),
          ),
          SizedBox(height: 12),
          _PathField(
            label: 'MCP 路径',
            controller: _mcpPath,
            hint: '~/.claude/mcp/',
            onPick: () => _pickDir(_mcpPath),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SecondaryButton(label: '取消', onPressed: () => Navigator.of(context).maybePop()),
              SizedBox(width: 8),
              PrimaryButton(label: '创建', onPressed: _confirm),
            ],
          ),
        ],
      ),
    );
  }

  Color _colorFor(AgentFormat f) {
    switch (f) {
      case AgentFormat.claudeCode: return AppColors.agentClaude;
      case AgentFormat.codex: return AppColors.agentCodex;
      case AgentFormat.opencode: return AppColors.agentOpenCode;
      case AgentFormat.hermes: return AppColors.agentHermes;
      case AgentFormat.trae: return const Color(0xFF7C3AED);
      case AgentFormat.zcode: return const Color(0xFF2563EB);
      case AgentFormat.workbuddy: return const Color(0xFF059669);
      case AgentFormat.generic: return AppColors.primary;
    }
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.controller, required this.hint});
  final String label;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.secondary),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.secondary,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(width: 0.5, color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(width: 1, color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

/// 带浏览按钮的路径输入框
class _PathField extends StatelessWidget {
  const _PathField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.onPick,
  });
  final String label;
  final TextEditingController controller;
  final String hint;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.secondary),
        SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTextStyles.secondary,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(width: 0.5, color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(width: 1, color: AppColors.primary),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Tooltip(
              message: '浏览...',
              child: IconButton.filledTonal(
                onPressed: onPick,
                icon: Icon(Icons.folder_open, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.bgSecondary,
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// 兼容导入 (CreateAgentRequest 已在 agent_repository.dart 中)
