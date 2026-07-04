// 对照 DESIGN_SPEC §3.3 技能市场页
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/models.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/toast.dart';
import '../dialogs/agent_selector_dialog.dart';
import '../dialogs/incompatible_warning.dart';

class MarketplacePage extends ConsumerStatefulWidget {
  const MarketplacePage({super.key});

  @override
  ConsumerState<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends ConsumerState<MarketplacePage> {
  List<MarketplaceRepo> _repos = const [];
  List<MarketplaceRepo> _filtered = const [];
  MarketplaceRepo? _selected;
  String _readme = '';
  bool _loadingList = true;
  bool _loadingReadme = false;
  String _searchQuery = '';
  String _category = '全部';
  bool _installing = false;
  Timer? _searchDebounce;
  int _searchVersion = 0;
  late final TextEditingController _searchCtrl;

  static const _categories = ['全部', '开发', '设计', '通用'];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _loadRepos();
  }

  Future<void> _loadRepos() async {
    setState(() {
      _loadingList = true;
    });
    try {
      final repos = await ref.read(marketplaceRepositoryProvider).repos();
      if (!mounted) return;
      setState(() {
        _repos = repos;
        _applyFilter();
        _loadingList = false;
        if (repos.isNotEmpty) {
          _selected = repos.first;
          _loadReadme(repos.first);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingList = false);
    }
  }

  void _applyFilter() {
    var list = _repos;
    if (_category != '全部') {
      list = list.where((r) => r.topics.contains(_category)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) =>
          r.name.toLowerCase().contains(q) ||
          r.owner.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q)).toList();
    }
    _filtered = list;
  }

  Future<void> _loadReadme(MarketplaceRepo repo) async {
    setState(() {
      _loadingReadme = true;
      _selected = repo;
    });
    final md = await ref.read(marketplaceRepositoryProvider).readmeHtml(repo.owner, repo.name);
    if (!mounted) return;
    setState(() {
      _readme = md;
      _loadingReadme = false;
    });
  }

  /// 搜索: 空查询走本地列表 (category 过滤), 非空查询走 GitHub 搜索 API。
  /// 400ms debounce, 用版本号避免竞态。
  void _onSearch(String q) {
    _searchDebounce?.cancel();
    setState(() => _searchQuery = q);
    if (q.isEmpty) {
      // 空查询: 立即回到本地过滤
      setState(() {
        _applyFilter();
        _loadingList = false;
      });
      return;
    }
    setState(() => _loadingList = true);
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _doSearch(q));
  }

  Future<void> _doSearch(String q) async {
    final myVersion = ++_searchVersion;
    try {
      final results = await ref.read(marketplaceRepositoryProvider).search(q);
      if (myVersion != _searchVersion || !mounted) return;
      setState(() {
        _filtered = results;
        _loadingList = false;
        // 选中项不在结果中则切换到第一项
        if (_selected == null ||
            !_filtered.any((r) => r.fullName == _selected!.fullName)) {
          _selected = _filtered.isNotEmpty ? _filtered.first : null;
          _readme = '';
          if (_selected != null) _loadReadme(_selected!);
        }
      });
    } catch (e) {
      if (myVersion != _searchVersion || !mounted) return;
      setState(() => _loadingList = false);
      showToast(context, '搜索失败: $e');
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _selectCategory(String c) {
    // 切换 category 时清空搜索框,回到本地列表 (避免与 GitHub 搜索结果冲突)
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() {
      _category = c;
      _searchQuery = '';
      _applyFilter();
    });
  }

  void _copyAddress() {
    if (_selected == null) return;
    final url = 'https://github.com/${_selected!.fullName}';
    Clipboard.setData(ClipboardData(text: url));
    showToast(context, '已复制地址: $url');
  }

  Future<void> _install() async {
    if (_selected == null) return;
    final agents = await ref.read(agentRepositoryProvider).list();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AgentSelectorDialog(
        agents: agents,
        onSelect: (agent) => _confirmInstall(agent, _selected!),
      ),
    );
  }

  Future<void> _confirmInstall(Agent agent, MarketplaceRepo repo) async {
    // Phase 1 简化: 模拟格式不兼容判定 (50% 概率触发警告用于演示)
    final incompatible = repo.topics.contains('claude-code') && agent.format != AgentFormat.claudeCode && agent.format != AgentFormat.generic;
    if (incompatible) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => IncompatibleWarning(
          skillName: repo.name,
          skillFormat: 'claude-code',
          agentName: agent.name,
          agentFormat: agent.format.label,
          onForceInstall: () => _doInstall(agent, repo, force: true),
        ),
      );
      return;
    }
    await _doInstall(agent, repo, force: false);
  }

  Future<void> _doInstall(Agent agent, MarketplaceRepo repo, {required bool force}) async {
    setState(() => _installing = true);
    try {
      // Flutter 端 90 秒超时 (Go 端 60 秒 clone + 拷贝余量)
      final skill = await ref
          .read(marketplaceRepositoryProvider)
          .install(InstallRequest(
            repo: repo.fullName,
            agentId: agent.id,
            force: force,
          ))
          .timeout(const Duration(seconds: 90), onTimeout: () {
        throw Exception('安装超时 (90 秒),可能是网络问题或仓库过大');
      });
      if (!mounted) return;
      final skillName = skill.name;
      showToast(context, '已安装 $skillName 到 ${agent.name}');
    } catch (e) {
      if (!mounted) return;
      showToast(context, '安装失败: $e');
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildCategoryBar(),
          Expanded(
            child: Row(
              children: [
                SizedBox(width: 260, child: _buildList()),
                Container(width: 0.5, color: AppColors.border),
                Expanded(child: _buildReadmePanel()),
              ],
            ),
          ),
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
          Text('技能市场', style: AppTextStyles.pageTitle),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('GitHub', style: AppTextStyles.micro.copyWith(color: AppColors.textSecondary)),
          ),
          Spacer(),
          SizedBox(
            width: 240,
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: '搜索仓库...',
                hintStyle: AppTextStyles.secondary,
                prefixIcon: Icon(Icons.search, size: 16, color: AppColors.textTertiary),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                filled: true,
                fillColor: AppColors.bgSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(bottom: BorderSide(width: 0.5, color: AppColors.border)),
      ),
      child: Row(
        children: _categories.map((c) {
          final selected = _category == c;
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _selectCategory(c),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(c, style: AppTextStyles.body.copyWith(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList() {
    if (_loadingList) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
    }
    if (_filtered.isEmpty) {
      return const EmptyState(title: '暂无仓库');
    }
    return ListView.builder(
      itemCount: _filtered.length,
      itemBuilder: (context, i) {
        final r = _filtered[i];
        final selected = _selected?.fullName == r.fullName;
        return InkWell(
          onTap: () => _loadReadme(r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.bgPrimary,
              border: Border(
                bottom: BorderSide(width: 0.5, color: AppColors.border),
                left: selected ? BorderSide(width: 2, color: AppColors.primary) : BorderSide.none,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.fullName, style: AppTextStyles.listItemPrimary, maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Text(r.description, style: AppTextStyles.secondary, maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star_outline, size: 12, color: AppColors.textTertiary),
                    SizedBox(width: 2),
                    Text('${r.stars}', style: AppTextStyles.micro),
                    SizedBox(width: 12),
                    if (r.license != null) ...[
                      Icon(Icons.balance, size: 12, color: AppColors.textTertiary),
                      SizedBox(width: 2),
                      Text(r.license!, style: AppTextStyles.micro),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadmePanel() {
    if (_selected == null) {
      return const EmptyState(title: '选择左侧仓库查看详情');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReadmeHeader(),
        Divider(height: 1, thickness: 0.5, color: AppColors.border),
        Expanded(
          child: _loadingReadme
              ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
              : Markdown(
                  data: _readme,
                  padding: EdgeInsets.all(20),
                  styleSheet: MarkdownStyleSheet(
                    h1: AppTextStyles.pageTitle.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
                    h2: AppTextStyles.panelTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                    p: AppTextStyles.body,
                    code: AppTextStyles.code.copyWith(backgroundColor: AppColors.bgSecondary),
                    codeblockDecoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    tableHead: AppTextStyles.secondary.copyWith(fontWeight: FontWeight.w600),
                    tableBody: AppTextStyles.body,
                    blockquoteDecoration: BoxDecoration(
                      border: Border(left: BorderSide(width: 2, color: AppColors.primary)),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildReadmeHeader() {
    final r = _selected!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.bgPrimary,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.fullName, style: AppTextStyles.pageTitle),
                SizedBox(height: 4),
                Row(
                  children: [
                    if (r.license != null) ...[
                      Text(r.license!, style: AppTextStyles.secondary),
                      SizedBox(width: 12),
                    ],
                    Text('★ ${r.stars}', style: AppTextStyles.secondary),
                    SizedBox(width: 12),
                    Text('branch: ${r.defaultBranch}', style: AppTextStyles.secondary),
                  ],
                ),
              ],
            ),
          ),
          TextButtonX(label: '复制地址', icon: Icons.copy, onPressed: _copyAddress),
          SizedBox(width: 8),
          PrimaryButton(
            label: _installing ? '安装中...' : '安装',
            icon: _installing ? null : Icons.download,
            onPressed: _installing ? null : _install,
          ),
        ],
      ),
    );
  }
}
