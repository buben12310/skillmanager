// 对照 DESIGN_SPEC §3.5 MCP 详情页
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/toast.dart';

class McpDetailPage extends ConsumerStatefulWidget {
  const McpDetailPage({
    super.key,
    required this.agent,
    required this.mcp,
    required this.onBack,
  });
  final Agent agent;
  final Mcp mcp;
  final VoidCallback onBack;

  @override
  ConsumerState<McpDetailPage> createState() => _McpDetailPageState();
}

class _McpDetailPageState extends ConsumerState<McpDetailPage> {
  late Mcp _mcp = widget.mcp;
  bool _testing = false;

  Future<void> _test() async {
    setState(() => _testing = true);
    try {
      final result = await ref.read(mcpRepositoryProvider).test(widget.agent.id, _mcp.id);
      if (!mounted) return;
      setState(() {
        _mcp = _mcp.copyWith(
          connected: result.connected,
          tools: result.tools,
          lastTestedAt: DateTime.now(),
        );
        _testing = false;
      });
      showToast(context, result.connected ? '连接成功,延迟 ${result.latencyMs}ms' : '连接失败');
    } catch (e) {
      if (!mounted) return;
      setState(() => _testing = false);
      showToast(context, '测试失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(20),
              children: [
                _buildConnectionCard(),
                SizedBox(height: 16),
                _buildSection('配置', [
                  _InfoRow(label: '名称', value: _mcp.name),
                  _InfoRow(label: '命令', value: _mcp.command, mono: true),
                  _InfoRow(label: '参数', value: _mcp.args.join(' '), mono: true),
                  _InfoRow(label: '路径', value: _mcp.path, mono: true),
                ]),
                SizedBox(height: 16),
                _buildSection('可用工具', [
                  if (_mcp.tools.isEmpty)
                    Text('暂无工具', style: AppTextStyles.secondary)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _mcp.tools.map((t) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.mcpBadgeBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(t, style: AppTextStyles.code.copyWith(color: AppColors.mcpBadgeText, fontSize: 11)),
                        );
                      }).toList(),
                    ),
                ]),
                if (_mcp.lastTestedAt != null) ...[
                  SizedBox(height: 16),
                  _buildSection('最近测试', [
                    Text(_formatTime(_mcp.lastTestedAt!), style: AppTextStyles.secondary),
                  ]),
                ],
              ],
            ),
          ),
          _buildActionBar(),
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
          TypeBadge(kind: TypeKind.mcp),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_mcp.name, style: AppTextStyles.pageTitle),
                Text(widget.agent.name, style: AppTextStyles.secondary),
              ],
            ),
          ),
          SecondaryButton(label: '编辑', icon: Icons.edit, onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildConnectionCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 0.5, color: AppColors.border),
      ),
      child: Row(
        children: [
          StatusBadge(
            label: _mcp.connected ? '已连接' : '断开',
            tone: _mcp.connected ? BadgeTone.normal : BadgeTone.error,
          ),
          if (_mcp.tools.isNotEmpty) ...[
            SizedBox(width: 12),
            Text('${_mcp.tools.length} 个工具', style: AppTextStyles.secondary),
          ],
          Spacer(),
          PrimaryButton(
            label: _testing ? '测试中...' : '测试连接',
            icon: _testing ? null : Icons.bolt,
            onPressed: _testing ? null : _test,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 0.5, color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.panelTitle),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(top: BorderSide(width: 0.5, color: AppColors.border)),
      ),
      child: Row(
        children: [
          SecondaryButton(label: '导出', icon: Icons.download, onPressed: () {}),
          Spacer(),
          DangerButton(label: '删除', onPressed: () {}),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
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
          SizedBox(width: 80, child: Text(label, style: AppTextStyles.secondary)),
          SizedBox(width: 12),
          Expanded(child: Text(value, style: mono ? AppTextStyles.code : AppTextStyles.body)),
        ],
      ),
    );
  }
}
