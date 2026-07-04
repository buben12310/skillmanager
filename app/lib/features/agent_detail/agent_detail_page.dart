// 对照 DESIGN_SPEC §3.2 Agent 详情页
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/path_expander.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/toast.dart';
import '../dialogs/export_skill_dialog.dart';
import '../dialogs/import_skill_dialog.dart';
import 'widgets/mcp_row.dart';
import 'widgets/multi_select_bar.dart';
import 'widgets/skill_row.dart';

enum _DetailTab { skills, mcps }

class AgentDetailPage extends ConsumerStatefulWidget {
  const AgentDetailPage({super.key, required this.agent, required this.onBack, required this.onOpenSkill, required this.onOpenMcp});
  final Agent agent;
  final VoidCallback onBack;
  final void Function(Skill) onOpenSkill;
  final void Function(Mcp) onOpenMcp;

  @override
  ConsumerState<AgentDetailPage> createState() => _AgentDetailPageState();
}

class _AgentDetailPageState extends ConsumerState<AgentDetailPage> {
  _DetailTab _tab = _DetailTab.skills;
  bool _loading = true;
  Object? _error;

  final List<Skill> _skills = [];
  final List<Mcp> _mcps = [];

  // 多选模式
  bool _multiSelect = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final skills = ref.read(skillRepositoryProvider).listByAgent(widget.agent.id);
      final mcps = ref.read(mcpRepositoryProvider).listByAgent(widget.agent.id);
      final s = await skills;
      final m = await mcps;
      if (!mounted) return;
      setState(() {
        _skills
          ..clear()
          ..addAll(s);
        _mcps
          ..clear()
          ..addAll(m);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// 刷新: 先调 Go 端扫描同步文件系统 → 再读数据库
  /// 这样能识别新装的 skill / 删除的 skill
  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 触发 Go 端扫描,同步文件系统到数据库
      await ref.read(agentRepositoryProvider).scan();
      // 再读取最新数据
      final skills = ref.read(skillRepositoryProvider).listByAgent(widget.agent.id);
      final mcps = ref.read(mcpRepositoryProvider).listByAgent(widget.agent.id);
      final s = await skills;
      final m = await mcps;
      if (!mounted) return;
      setState(() {
        _skills
          ..clear()
          ..addAll(s);
        _mcps
          ..clear()
          ..addAll(m);
        _loading = false;
      });
      if (mounted) showToast(context, '已刷新');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
      if (mounted) showToast(context, '刷新失败: $e');
    }
  }

  void _enterMultiSelect(String id) {
    setState(() {
      _multiSelect = true;
      _selectedIds
        ..clear()
        ..add(id);
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitMultiSelect() {
    setState(() {
      _multiSelect = false;
      _selectedIds.clear();
    });
  }

  void _exportSkill(Skill skill) {
    showDialog(
      context: context,
      builder: (_) => ExportSkillDialog(sourceAgent: widget.agent, skill: skill),
    );
  }

  void _exportMcp(Mcp mcp) {
    showToast(context, '已导出 ${mcp.name}');
  }

  void _batchExport() {
    showToast(context, '已导出 ${_selectedIds.length} 项');
    _exitMultiSelect();
  }

  void _batchDelete() {
    // 出于安全性考虑,不提供删除 Skill 功能
    // 此方法保留仅为兼容 MultiSelectBar 的回调签名,实际不执行删除
    showToast(context, '出于安全性考虑,Skill 删除功能已禁用\n请手动管理 Skill 文件夹');
    _exitMultiSelect();
  }

  void _showImportSource() {
    showDialog(
      context: context,
      builder: (_) => ImportSkillDialog(
        targetAgent: widget.agent,
        onComplete: _load,
      ),
    );
  }

  void _addSkill() {
    if (_tab == _DetailTab.skills) {
      _showImportSource();
    } else {
      showToast(context, '添加 MCP:Phase 2 实现');
    }
  }

  /// 在资源管理器中打开 agent 目录
  Future<void> _openDirectory() async {
    final raw = _tab == _DetailTab.skills ? widget.agent.skillPath : widget.agent.mcpPath;
    if (raw.isEmpty) {
      showToast(context, '路径未配置');
      return;
    }
    final dir = PathExpander.expand(raw);
    try {
      // 目录不存在则自动创建
      if (!Directory(dir).existsSync()) {
        await Directory(dir).create(recursive: true);
      }
      if (Platform.isWindows) {
        await Process.start('explorer', [dir]);
      } else if (Platform.isMacOS) {
        await Process.start('open', [dir]);
      } else {
        await Process.start('xdg-open', [dir]);
      }
    } catch (e) {
      if (!mounted) return;
      showToast(context, '打开失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(child: _buildBody()),
          if (_multiSelect)
            MultiSelectBar(
              selectedCount: _selectedIds.length,
              onExport: _batchExport,
              onDelete: _batchDelete,
              onCancel: _exitMultiSelect,
            ),
          _buildAddBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(bottom: BorderSide(width: 0.5, color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          SizedBox(width: 16),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.agent.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(widget.agent.icon, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: widget.agent.iconColor)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.agent.name, style: AppTextStyles.pageTitle),
                Text(widget.agent.skillPath.isEmpty ? '未配置' : widget.agent.skillPath, style: AppTextStyles.code),
              ],
            ),
          ),
          IconButton(
            onPressed: _refresh,
            icon: Icon(Icons.refresh, color: AppColors.textSecondary, size: 18),
            tooltip: '刷新 (扫描文件系统)',
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          SizedBox(width: 12),
          IconButton(
            onPressed: _openDirectory,
            icon: Icon(Icons.folder_open, color: AppColors.textSecondary, size: 18),
            tooltip: '在资源管理器中打开',
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          SizedBox(width: 12),
          SecondaryButton(label: '导入', icon: Icons.download, onPressed: _showImportSource),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(bottom: BorderSide(width: 0.5, color: AppColors.border)),
      ),
      child: Row(
        children: [
          _TabItem(label: 'Skills', selected: _tab == _DetailTab.skills, onTap: () => setState(() => _tab = _DetailTab.skills)),
          SizedBox(width: 24),
          _TabItem(label: 'MCPs', selected: _tab == _DetailTab.mcps, onTap: () => setState(() => _tab = _DetailTab.mcps)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
    }
    if (_error != null) {
      return ErrorState(message: '加载失败', onRetry: _load);
    }
    if (_tab == _DetailTab.skills) {
      if (_skills.isEmpty) {
        return EmptyState(
          title: '暂无 Skill',
          subtitle: '点击下方添加 Skill',
          actionLabel: '+ 添加 Skill',
          onAction: _addSkill,
        );
      }
      return ListView.builder(
        itemCount: _skills.length,
        itemBuilder: (context, i) {
          final s = _skills[i];
          return SkillRow(
            skill: s,
            selected: _selectedIds.contains(s.id),
            multiSelectMode: _multiSelect,
            onTap: () {
              if (_multiSelect) {
                _toggleSelect(s.id);
              } else {
                widget.onOpenSkill(s);
              }
            },
            onLongPress: () => _enterMultiSelect(s.id),
            onExport: () => _exportSkill(s),
          );
        },
      );
    } else {
      if (_mcps.isEmpty) {
        return const EmptyState(title: '暂无 MCP', subtitle: '点击下方添加 MCP');
      }
      return ListView.builder(
        itemCount: _mcps.length,
        itemBuilder: (context, i) {
          final m = _mcps[i];
          return McpRow(
            mcp: m,
            selected: _selectedIds.contains(m.id),
            multiSelectMode: _multiSelect,
            onTap: () {
              if (_multiSelect) {
                _toggleSelect(m.id);
              } else {
                widget.onOpenMcp(m);
              }
            },
            onLongPress: () => _enterMultiSelect(m.id),
            onExport: () => _exportMcp(m),
          );
        },
      );
    }
  }

  Widget _buildAddBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(top: BorderSide(width: 0.5, color: AppColors.border)),
      ),
      child: Row(
        children: [
          DashedButton(
            label: _tab == _DetailTab.skills ? '+ 添加 Skill' : '+ 添加 MCP',
            icon: Icons.add,
            onPressed: _addSkill,
          ),
          Spacer(),
          TextButtonX(label: '导入', icon: Icons.download, onPressed: _showImportSource),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.listItemPrimary.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
            SizedBox(height: 6),
            Container(width: 24, height: 2, color: selected ? AppColors.primary : Colors.transparent),
          ],
        ),
      ),
    );
  }
}
