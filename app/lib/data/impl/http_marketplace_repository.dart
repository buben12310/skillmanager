import '../models/models.dart';
import '../repositories/marketplace_repository.dart';
import 'http_client.dart';

class HttpMarketplaceRepository implements MarketplaceRepository {
  HttpMarketplaceRepository(this._http);
  final HttpClientHelper _http;

  @override
  Future<List<MarketplaceRepo>> repos({String? category, int page = 1}) async {
    final cat = category ?? '全部';
    final list = (await _http.get('/marketplace/repos?category=$cat') as List)
        .cast<Map<String, dynamic>>();
    return list.map(_parse).toList();
  }

  @override
  Future<MarketplaceRepo> repo(String owner, String name) async {
    final j = await _http.get('/marketplace/repos/$owner/$name');
    return _parse(j as Map<String, dynamic>);
  }

  @override
  Future<String> readmeHtml(String owner, String name) async {
    final j = await _http.get('/marketplace/repos/$owner/$name/readme')
        as Map<String, dynamic>;
    return j['readme'] as String? ?? '';
  }

  @override
  Future<List<MarketplaceRepo>> search(String query) async {
    final list = (await _http.get('/marketplace/search?q=${Uri.encodeQueryComponent(query)}') as List)
        .cast<Map<String, dynamic>>();
    return list.map(_parse).toList();
  }

  @override
  Future<Skill> install(InstallRequest req) async {
    final j = await _http.post('/marketplace/install', {
      'repo': req.repo,
      'agentId': req.agentId,
      'subPath': req.subPath ?? '',
      'force': req.force,
    });
    return _parseSkill(j as Map<String, dynamic>);
  }

  MarketplaceRepo _parse(Map<String, dynamic> j) => MarketplaceRepo(
        owner: j['owner'] as String,
        name: j['name'] as String,
        description: (j['description'] as String?) ?? '',
        stars: (j['stars'] as num?)?.toInt() ?? 0,
        license: (j['license'] as String?)?.isNotEmpty == true
            ? j['license'] as String
            : null,
        defaultBranch: (j['defaultBranch'] as String?) ?? 'main',
        topics: ((j['topics'] as List?) ?? const []).cast<String>(),
      );

  Skill _parseSkill(Map<String, dynamic> j) => Skill(
        id: (j['id'] as String?) ?? '',
        agentId: (j['agentId'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        version: (j['version'] as String?) ?? '',
        author: (j['author'] as String?) ?? '',
        source: SkillSource.marketplace,
        sourceUrl: (j['sourceUrl'] as String?) ?? '',
        path: (j['path'] as String?) ?? '',
        enabled: (j['enabled'] as bool?) ?? true,
        format: AgentFormat.generic,
        dependencies: const [],
        installedAt: DateTime.tryParse((j['installedAt'] as String?) ?? '') ??
            DateTime.now(),
      );
}
