import '../models/models.dart';
import '../repositories/skill_repository.dart';

class MockSkillRepository implements SkillRepository {
  MockSkillRepository() : _skills = _seed();

  final List<Skill> _skills;

  static List<Skill> _seed() {
    return [
      Skill(
        id: 's1',
        agentId: 'a1',
        name: 'agent-skills',
        version: '1.0.0',
        author: 'Google',
        source: SkillSource.marketplace,
        sourceUrl: 'github.com/addyosmani/agent-skills',
        path: '/Users/buben/.claude/skills/agent-skills/',
        enabled: true,
        format: AgentFormat.claudeCode,
        dependencies: const [],
        installedAt: DateTime(2026, 6, 22),
      ),
      Skill(
        id: 's2',
        agentId: 'a1',
        name: 'obsidian-retrieval',
        version: '2.1.0',
        author: '本地',
        source: SkillSource.local,
        path: '/Users/buben/.claude/skills/obsidian-retrieval/',
        enabled: false,
        format: AgentFormat.claudeCode,
        dependencies: const [],
        installedAt: DateTime(2026, 6, 21),
      ),
      Skill(
        id: 's3',
        agentId: 'a1',
        name: 'wb-finance-skill',
        version: '1.2.0',
        author: 'Builtin',
        source: SkillSource.builtin,
        path: '/Users/buben/.claude/skills/wb-finance-skill/',
        enabled: true,
        format: AgentFormat.claudeCode,
        dependencies: const [],
        installedAt: DateTime(2026, 6, 20),
      ),
      Skill(
        id: 's4',
        agentId: 'a2',
        name: 'codex-prime',
        version: '0.9.0',
        author: 'Codex',
        source: SkillSource.local,
        path: '/Users/buben/.codex/skills/codex-prime/',
        enabled: true,
        format: AgentFormat.codex,
        dependencies: const [],
        installedAt: DateTime(2026, 6, 19),
      ),
      Skill(
        id: 's5',
        agentId: 'a3',
        name: 'open-code-review',
        version: '1.5.0',
        author: 'OpenCode',
        source: SkillSource.local,
        path: '/Users/buben/.opencode/skills/open-code-review/',
        enabled: true,
        format: AgentFormat.opencode,
        dependencies: const [],
        installedAt: DateTime(2026, 6, 18),
      ),
      Skill(
        id: 's6',
        agentId: 'a3',
        name: 'open-spec-writer',
        version: '2.0.0',
        author: 'OpenCode',
        source: SkillSource.local,
        path: '/Users/buben/.opencode/skills/open-spec-writer/',
        enabled: false,
        format: AgentFormat.opencode,
        dependencies: const [],
        installedAt: DateTime(2026, 6, 17),
      ),
    ];
  }

  @override
  Future<List<Skill>> listByAgent(String agentId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _skills.where((s) => s.agentId == agentId).toList();
  }

  @override
  Future<Skill> get(String agentId, String skillId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _skills.firstWhere((s) => s.agentId == agentId && s.id == skillId);
  }

  @override
  Future<Skill> add(String agentId, AddSkillRequest req) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final skill = Skill(
      id: 's${_skills.length + 1}-${DateTime.now().millisecondsSinceEpoch}',
      agentId: agentId,
      name: req.name,
      version: '1.0.0',
      source: SkillSource.local,
      path: req.path,
      enabled: true,
      format: req.format,
      dependencies: const [],
      installedAt: DateTime.now(),
    );
    _skills.add(skill);
    return skill;
  }

  @override
  Future<void> delete(String agentId, String skillId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _skills.removeWhere((s) => s.agentId == agentId && s.id == skillId);
  }

  @override
  Future<Skill> toggle(String agentId, String skillId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final i = _skills.indexWhere((s) => s.agentId == agentId && s.id == skillId);
    if (i >= 0) {
      _skills[i] = _skills[i].copyWith(enabled: !_skills[i].enabled);
      return _skills[i];
    }
    throw StateError('skill not found');
  }

  @override
  Future<String> readme(String agentId, String skillId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return '''# agent-skills

24 种覆盖软件开发全生命周期的生产级工程技能库。

## 包含技能

- code-review
- prd-writer
- test-gen
- +21 more

## 安装

```
git clone https://github.com/addyosmani/agent-skills.git
```
''';
  }

  @override
  Future<Skill> exportToAgent(String sourceAgentId, String skillId, String targetAgentId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final src = _skills.firstWhere((s) => s.agentId == sourceAgentId && s.id == skillId);
    final newSkill = Skill(
      id: 's${_skills.length + 1}-${DateTime.now().millisecondsSinceEpoch}',
      agentId: targetAgentId,
      name: src.name,
      version: src.version,
      author: src.author,
      source: SkillSource.import,
      sourceUrl: src.sourceUrl,
      path: '/mock/$targetAgentId/${src.name}/',
      enabled: true,
      format: src.format,
      dependencies: src.dependencies,
      installedAt: DateTime.now(),
    );
    _skills.add(newSkill);
    return newSkill;
  }
}
