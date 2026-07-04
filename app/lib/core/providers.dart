import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/impl/http_agent_repository.dart';
import '../data/impl/http_client.dart';
import '../data/impl/http_marketplace_repository.dart';
import '../data/impl/http_mcp_repository.dart';
import '../data/impl/http_skill_repository.dart';
import '../data/repositories/agent_repository.dart';
import '../data/repositories/mcp_repository.dart';
import '../data/repositories/marketplace_repository.dart';
import '../data/repositories/skill_repository.dart';
import 'process_launcher.dart';

// Phase 3 (M6): 全部接 Go 内核 (含 GitHub 市场)
final processLauncherProvider = Provider<ProcessLauncher>((ref) {
  return ProcessLauncher();
});

final httpClientProvider = Provider<HttpClientHelper>((ref) {
  return HttpClientHelper(ref.watch(processLauncherProvider));
});

final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return HttpAgentRepository(ref.watch(processLauncherProvider));
});

final skillRepositoryProvider = Provider<SkillRepository>((ref) {
  return HttpSkillRepository(ref.watch(httpClientProvider));
});

final mcpRepositoryProvider = Provider<McpRepository>((ref) {
  return HttpMcpRepository(ref.watch(httpClientProvider));
});

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return HttpMarketplaceRepository(ref.watch(httpClientProvider));
});

final agentsProvider = FutureProvider<List>((ref) async {
  return ref.watch(agentRepositoryProvider).list();
});
