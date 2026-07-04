import '../../core/theme/app_colors.dart';
import '../models/models.dart';
import '../repositories/agent_repository.dart';

class MockAgentRepository implements AgentRepository {
  MockAgentRepository() : _agents = _seed();

  final List<Agent> _agents;

  static List<Agent> _seed() {
    return [
      Agent.mock(
        id: 'a1',
        name: 'Claude Code',
        icon: 'CC',
        iconColor: AppColors.agentClaude,
        skillPath: '/Users/buben/.claude/skills/',
        mcpPath: '/Users/buben/.claude/mcp/',
        format: AgentFormat.claudeCode,
      ),
      Agent.mock(
        id: 'a2',
        name: 'Codex',
        icon: 'CX',
        iconColor: AppColors.agentCodex,
        skillPath: '/Users/buben/.codex/skills/',
        mcpPath: '/Users/buben/.codex/mcp/',
        format: AgentFormat.codex,
      ),
      Agent.mock(
        id: 'a3',
        name: 'OpenCode',
        icon: 'OC',
        iconColor: AppColors.agentOpenCode,
        skillPath: '/Users/buben/.opencode/skills/',
        mcpPath: '/Users/buben/.opencode/mcp/',
        format: AgentFormat.opencode,
      ),
      Agent.mock(
        id: 'a4',
        name: 'Hermes',
        icon: 'HE',
        iconColor: AppColors.agentHermes,
        skillPath: '',
        mcpPath: '',
        format: AgentFormat.hermes,
        status: AgentStatus.unconfigured,
      ),
    ];
  }

  @override
  Future<List<Agent>> list() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_agents);
  }

  @override
  Future<Agent> get(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _agents.firstWhere((a) => a.id == id);
  }

  @override
  Future<Agent> create(CreateAgentRequest req) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final agent = Agent(
      id: 'a${_agents.length + 1}-${DateTime.now().millisecondsSinceEpoch}',
      name: req.name,
      icon: req.icon,
      iconColor: req.iconColor,
      skillPath: req.skillPath,
      mcpPath: req.mcpPath,
      status: AgentStatus.active,
      format: req.format,
      createdAt: DateTime.now(),
    );
    _agents.add(agent);
    return agent;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _agents.removeWhere((a) => a.id == id);
  }

  @override
  Future<List<DiscoveredAgent>> scan() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    // Mock 扫描结果
    return [
      DiscoveredAgent(type: AgentFormat.claudeCode, path: '/Users/buben/.claude', existing: true),
      DiscoveredAgent(type: AgentFormat.opencode, path: '/Users/buben/.opencode', existing: true),
      DiscoveredAgent(type: AgentFormat.codex, path: '/Users/buben/.codex', existing: false),
    ];
  }
}
