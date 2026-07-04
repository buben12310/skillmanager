import '../models/models.dart';

class TestResult {
  final bool connected;
  final List<String> tools;
  final int latencyMs;
  TestResult({required this.connected, required this.tools, required this.latencyMs});
}

abstract class McpRepository {
  Future<List<Mcp>> listByAgent(String agentId);
  Future<Mcp> get(String agentId, String mcpId);
  Future<void> delete(String agentId, String mcpId);
  Future<TestResult> test(String agentId, String mcpId); // ← Phase 2 接 Go connector
}
