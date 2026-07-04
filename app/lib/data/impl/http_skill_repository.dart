import '../models/models.dart';
import '../repositories/skill_repository.dart';
import 'http_client.dart';

class HttpSkillRepository implements SkillRepository {
  HttpSkillRepository(this._http);
  final HttpClientHelper _http;

  @override
  Future<List<Skill>> listByAgent(String agentId) async {
    final list = (await _http.get('/agents/$agentId/skills') as List)
        .cast<Map<String, dynamic>>();
    return list.map(_parse).toList();
  }

  @override
  Future<Skill> get(String agentId, String skillId) async {
    final j = await _http.get('/agents/$agentId/skills/$skillId');
    return _parse(j as Map<String, dynamic>);
  }

  @override
  Future<Skill> add(String agentId, AddSkillRequest req) async {
    final j = await _http.post('/agents/$agentId/skills', {
      'name': req.name,
      'path': req.path,
      'format': req.format.label,
      'source': 'local',
    });
    return _parse(j as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String agentId, String skillId) async {
    await _http.delete('/agents/$agentId/skills/$skillId');
  }

  @override
  Future<Skill> toggle(String agentId, String skillId) async {
    final j = await _http.send('PATCH', '/agents/$agentId/skills/$skillId/toggle')
        as Map<String, dynamic>;
    final enabled = j['enabled'] as bool;
    final cur = await get(agentId, skillId);
    return cur.copyWith(enabled: enabled);
  }

  @override
  Future<String> readme(String agentId, String skillId) async => '';

  @override
  Future<Skill> exportToAgent(String sourceAgentId, String skillId, String targetAgentId) async {
    final j = await _http.post('/agents/$sourceAgentId/skills/$skillId/export', {
      'targetAgentId': targetAgentId,
    });
    return _parse(j as Map<String, dynamic>);
  }

  Skill _parse(Map<String, dynamic> j) => Skill(
        id: j['id'] as String,
        agentId: j['agentId'] as String,
        name: j['name'] as String,
        version: (j['version'] as String?) ?? '',
        author: (j['author'] as String?) ?? '',
        source: _sourceFromStr((j['source'] as String?) ?? 'local'),
        sourceUrl: j['sourceUrl'] as String?,
        path: j['path'] as String,
        enabled: j['enabled'] as bool,
        format: _formatFromStr((j['format'] as String?) ?? 'generic'),
        dependencies: ((j['dependencies'] as List?) ?? const [])
            .cast<String>(),
        installedAt: DateTime.tryParse((j['installedAt'] as String?) ?? '') ??
            DateTime.now(),
      );

  SkillSource _sourceFromStr(String s) {
    switch (s) {
      case 'marketplace': return SkillSource.marketplace;
      case 'builtin': return SkillSource.builtin;
      case 'import': return SkillSource.import;
      default: return SkillSource.local;
    }
  }

  AgentFormat _formatFromStr(String s) {
    switch (s) {
      case 'claude-code': return AgentFormat.claudeCode;
      case 'codex': return AgentFormat.codex;
      case 'opencode': return AgentFormat.opencode;
      case 'hermes': return AgentFormat.hermes;
      case 'trae': return AgentFormat.trae;
      case 'zcode': return AgentFormat.zcode;
      case 'workbuddy': return AgentFormat.workbuddy;
      default: return AgentFormat.generic;
    }
  }
}
