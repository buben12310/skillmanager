import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/empty_state.dart';
import 'widgets/agent_row.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, required this.onOpenAgent, required this.onNewAgent, required this.onScan});
  final void Function(Agent agent) onOpenAgent;
  final VoidCallback onNewAgent;
  final Future<void> Function() onScan;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  List<Agent> _agents = const [];
  bool _loading = true;
  Object? _error;

  // 每个 Agent 的 Skills/MCPs 计数
  final Map<String, int> _skillCounts = {};
  final Map<String, int> _mcpCounts = {};

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
      final agents = await ref.read(agentRepositoryProvider).list();
      final skills = ref.read(skillRepositoryProvider);
      final mcps = ref.read(mcpRepositoryProvider);
      _skillCounts.clear();
      _mcpCounts.clear();
      for (final a in agents) {
        final s = await skills.listByAgent(a.id);
        final m = await mcps.listByAgent(a.id);
        _skillCounts[a.id] = s.length;
        _mcpCounts[a.id] = m.length;
      }
      if (!mounted) return;
      setState(() {
        _agents = agents;
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

  Future<void> _scan() async {
    await widget.onScan();
    await _load();
  }

  void _newAgent() {
    widget.onNewAgent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _TopBar(onScan: _scan, onNew: _newAgent),
          _TableHeader(),
          Expanded(
            child: _loading
                ? const _Skeleton()
                : _error != null
                    ? ErrorState(
                        message: '加载失败: $_error',
                        onRetry: _load,
                      )
                    : _agents.isEmpty
                        ? EmptyState(
                            title: '暂无 Agent',
                            subtitle: '点击「扫描」检测已安装的 Agent',
                            actionLabel: '扫描',
                            onAction: _scan,
                          )
                        : ListView.builder(
                            itemCount: _agents.length,
                            itemBuilder: (context, i) {
                              final a = _agents[i];
                              return AgentRow(
                                agent: a,
                                skillCount: _skillCounts[a.id] ?? 0,
                                mcpCount: _mcpCounts[a.id] ?? 0,
                                onTap: () => widget.onOpenAgent(a),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onScan, required this.onNew});
  final VoidCallback onScan;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(bottom: BorderSide(width: 0.5, color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
          SizedBox(width: 10),
          Text('Agent Skill Manager', style: AppTextStyles.pageTitle),
          Spacer(),
          SecondaryButton(label: '扫描', icon: Icons.search, onPressed: onScan),
          SizedBox(width: 8),
          PrimaryButton(label: '新建 Agent', icon: Icons.add, onPressed: onNew),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: AppColors.bgSecondary,
      child: Row(
        children: [
          const SizedBox(width: 48), // 图标列对齐
          const SizedBox(width: 12),
          Expanded(child: Text('名称', style: AppTextStyles.micro)),
          SizedBox(width: 48, child: Text('Skills', style: AppTextStyles.micro, textAlign: TextAlign.center)),
          SizedBox(width: 48, child: Text('MCPs', style: AppTextStyles.micro, textAlign: TextAlign.center)),
          const SizedBox(width: 56), // 状态点+箭头占位
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, i) => Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(width: 0.5, color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8))),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 14, color: AppColors.bgSecondary),
                  SizedBox(height: 6),
                  Container(width: 200, height: 12, color: AppColors.bgSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
