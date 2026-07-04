import '../models/models.dart';
import '../repositories/mcp_repository.dart';

class MockMcpRepository implements McpRepository {
  MockMcpRepository() : _mcps = _seed();

  final List<Mcp> _mcps;

  static List<Mcp> _seed() {
    return [
      Mcp(
        id: 'm1',
        agentId: 'a1',
        name: 'obsidian',
        command: 'npx',
        args: const ['-y', '@anthropic/mcp-obsidian'],
        path: '/Users/buben/.claude/mcp/obsidian.json',
        connected: true,
        tools: const ['read_note', 'write_note', 'search_notes', 'list_tags', 'create_folder', 'delete_note', 'rename_note', 'tag_note'],
      ),
      Mcp(
        id: 'm2',
        agentId: 'a1',
        name: 'filesystem',
        command: 'npx',
        args: const ['-y', '@modelcontextprotocol/server-filesystem'],
        path: '/Users/buben/.claude/mcp/filesystem.json',
        connected: false,
        tools: const [],
      ),
      Mcp(
        id: 'm3',
        agentId: 'a2',
        name: 'git',
        command: 'npx',
        args: const ['-y', '@modelcontextprotocol/server-git'],
        path: '/Users/buben/.codex/mcp/git.json',
        connected: true,
        tools: const ['git_status', 'git_diff', 'git_log', 'git_commit'],
      ),
      Mcp(
        id: 'm4',
        agentId: 'a3',
        name: 'memory',
        command: 'npx',
        args: const ['-y', '@modelcontextprotocol/server-memory'],
        path: '/Users/buben/.opencode/mcp/memory.json',
        connected: true,
        tools: const ['store', 'recall', 'forget', 'list'],
      ),
    ];
  }

  @override
  Future<List<Mcp>> listByAgent(String agentId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _mcps.where((m) => m.agentId == agentId).toList();
  }

  @override
  Future<Mcp> get(String agentId, String mcpId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mcps.firstWhere((m) => m.agentId == agentId && m.id == mcpId);
  }

  @override
  Future<void> delete(String agentId, String mcpId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mcps.removeWhere((m) => m.agentId == agentId && m.id == mcpId);
  }

  @override
  Future<TestResult> test(String agentId, String mcpId) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final mcp = _mcps.firstWhere((m) => m.agentId == agentId && m.id == mcpId);
    // Mock: 翻转连接状态
    final i = _mcps.indexWhere((m) => m.agentId == agentId && m.id == mcpId);
    final newConnected = !mcp.connected;
    final newTools = newConnected
        ? (mcp.tools.isEmpty ? const ['mock_tool_a', 'mock_tool_b'] : mcp.tools)
        : const <String>[];
    _mcps[i] = mcp.copyWith(connected: newConnected, tools: newTools, lastTestedAt: DateTime.now());
    return TestResult(connected: newConnected, tools: newTools, latencyMs: 120);
  }
}
