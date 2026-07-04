import '../models/models.dart';
import '../repositories/mcp_repository.dart';
import 'http_client.dart';

class HttpMcpRepository implements McpRepository {
  HttpMcpRepository(this._http);
  final HttpClientHelper _http;

  @override
  Future<List<Mcp>> listByAgent(String agentId) async {
    final list = (await _http.get('/agents/$agentId/mcps') as List)
        .cast<Map<String, dynamic>>();
    return list.map(_parse).toList();
  }

  @override
  Future<Mcp> get(String agentId, String mcpId) async {
    final j = await _http.get('/agents/$agentId/mcps/$mcpId');
    return _parse(j as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String agentId, String mcpId) async {
    await _http.delete('/agents/$agentId/mcps/$mcpId');
  }

  @override
  Future<TestResult> test(String agentId, String mcpId) async {
    final j = await _http.post('/agents/$agentId/mcps/$mcpId/test', {})
        as Map<String, dynamic>;
    return TestResult(
      connected: j['connected'] as bool,
      tools: ((j['tools'] as List?) ?? const []).cast<String>(),
      latencyMs: (j['latencyMs'] as num?)?.toInt() ?? 0,
    );
  }

  Mcp _parse(Map<String, dynamic> j) => Mcp(
        id: j['id'] as String,
        agentId: j['agentId'] as String,
        name: j['name'] as String,
        command: (j['command'] as String?) ?? '',
        args: ((j['args'] as List?) ?? const []).cast<String>(),
        path: (j['path'] as String?) ?? '',
        connected: j['connected'] as bool? ?? false,
        tools: ((j['tools'] as List?) ?? const []).cast<String>(),
        lastTestedAt: DateTime.tryParse((j['lastTestedAt'] as String?) ?? ''),
      );
}
