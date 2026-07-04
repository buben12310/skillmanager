import '../models/models.dart';
import '../repositories/marketplace_repository.dart';

class MockMarketplaceRepository implements MarketplaceRepository {
  MockMarketplaceRepository() : _repos = _seed();

  final List<MarketplaceRepo> _repos;

  static List<MarketplaceRepo> _seed() {
    return [
      MarketplaceRepo(
        owner: 'addyosmani',
        name: 'agent-skills',
        description: '为 AI 编程代理人设计的生产级工程技能库',
        stars: 19000,
        license: 'MIT',
        defaultBranch: 'main',
        topics: const ['开发', 'claude-code', 'agent-skills', 'engineering'],
      ),
      MarketplaceRepo(
        owner: 'obra',
        name: 'superpowers',
        description: '为 Claude Code 增强的超能力技能包',
        stars: 8500,
        license: 'MIT',
        defaultBranch: 'main',
        topics: const ['开发', 'claude-code', 'skills', 'productivity'],
      ),
      MarketplaceRepo(
        owner: 'obra',
        name: 'skills',
        description: '通用 Agent Skills 集合',
        stars: 4200,
        license: 'Apache-2.0',
        defaultBranch: 'main',
        topics: const ['通用', 'agent', 'skills', 'mcp'],
      ),
      MarketplaceRepo(
        owner: 'wshobson',
        name: 'agents',
        description: 'Claude Code agents collection',
        stars: 3100,
        license: 'MIT',
        defaultBranch: 'main',
        topics: const ['设计', 'claude-code', 'agents'],
      ),
      MarketplaceRepo(
        owner: 'notia',
        name: 'wb-finance-skill',
        description: '财务管理内置技能示例',
        stars: 0,
        license: null,
        defaultBranch: 'main',
        topics: const ['通用', 'builtin', 'finance'],
      ),
    ];
  }

  @override
  Future<List<MarketplaceRepo>> repos({String? category, int page = 1}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (category == null || category == '全部') return List.unmodifiable(_repos);
    return _repos.where((r) => r.topics.any((t) => t == category)).toList();
  }

  @override
  Future<MarketplaceRepo> repo(String owner, String name) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _repos.firstWhere((r) => r.owner == owner && r.name == name);
  }

  @override
  Future<String> readmeHtml(String owner, String name) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _readmeFor(owner, name);
  }

  @override
  Future<List<MarketplaceRepo>> search(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final q = query.toLowerCase();
    return _repos
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            r.owner.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<Skill> install(InstallRequest req) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final parts = req.repo.split('/');
    return Skill(
      id: 'installed-${DateTime.now().millisecondsSinceEpoch}',
      agentId: req.agentId,
      name: parts.last,
      version: '1.0.0',
      author: parts.first,
      source: SkillSource.marketplace,
      sourceUrl: 'github.com/${req.repo}',
      path: '/installed/${req.repo}/${req.subPath ?? ''}',
      enabled: true,
      format: AgentFormat.claudeCode,
      dependencies: const [],
      installedAt: DateTime.now(),
    );
  }

  String _readmeFor(String owner, String name) {
    switch ('$owner/$name') {
      case 'addyosmani/agent-skills':
        return '''# Agent Skills

为 AI 编程代理人设计的**生产级工程技能库**。

24 种覆盖软件开发全生命周期的工程技能。

## 核心亮点

- 完整的开发生命周期覆盖
- 7 个触发命令,一键激活
- 20 个核心技能,每个都是结构化工作流

## 包含技能

| 阶段 | 技能 |
|------|------|
| 定义 | `idea-refine` `spec-driven-development` |
| 规划 | `planning-and-task-breakdown` |
| 构建 | `incremental-implementation` `test-driven-development` |
| 评审 | `code-review-and-quality` `code-simplification` |
| 发布 | `git-workflow-and-versioning` `shipping-and-launch` |

## 安装

```
git clone https://github.com/addyosmani/agent-skills.git
```

## License

MIT
''';
      case 'obra/superpowers':
        return '''# Superpowers

为 Claude Code 增强的超能力技能包。

## 包含技能

- `context-engineering` 上下文工程
- `debugging-and-error-recovery` 调试与错误恢复
- `frontend-ui-engineering` 前端 UI 工程
- `api-and-interface-design` API 与接口设计

## 安装

```
git clone https://github.com/obra/superpowers.git
```

## License

MIT
''';
      case 'obra/skills':
        return '''# Skills

通用 Agent Skills 集合。

## 包含

- `source-driven-development` 源驱动开发
- `doubt-driven-development` 疑虑驱动开发
- `interview-me` 自我访谈

## License

Apache-2.0
''';
      case 'wshobson/agents':
        return '''# Agents

Claude Code agents collection。

## 设计师视角

聚焦于 UI/UX 设计场景的技能集合:

- `design-system-builder` 设计系统构建
- `wireframe-to-code` 线框图转代码
- `accessibility-auditor` 可访问性审计

## License

MIT
''';
      case 'notia/wb-finance-skill':
        return '''# WB Finance Skill

财务管理内置技能示例。

## 功能

- 收支记账
- 资产负债分析
- 投资组合追踪

> 该技能仅作 UI 展示用途,Phase 3 网络市场上线后才会真实安装。
''';
      default:
        return '# $owner/$name\n\nREADME 暂未提供。';
    }
  }
}
