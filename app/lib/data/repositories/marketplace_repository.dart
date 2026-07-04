import '../models/models.dart';

class InstallRequest {
  final String repo; // "owner/name"
  final String agentId;
  final bool force;
  final String? subPath;
  InstallRequest({required this.repo, required this.agentId, this.force = false, this.subPath});
}

abstract class MarketplaceRepository {
  Future<List<MarketplaceRepo>> repos({String? category, int page = 1});
  Future<MarketplaceRepo> repo(String owner, String name);
  Future<String> readmeHtml(String owner, String name); // 返回 Markdown 字符串
  Future<List<MarketplaceRepo>> search(String query);
  Future<Skill> install(InstallRequest req); // ← Phase 3 接 GitHub
}
