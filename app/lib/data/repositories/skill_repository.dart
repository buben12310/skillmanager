import '../models/models.dart';

class AddSkillRequest {
  final String name;
  final String path;
  final AgentFormat format;
  AddSkillRequest({required this.name, required this.path, required this.format});
}

abstract class SkillRepository {
  Future<List<Skill>> listByAgent(String agentId);
  Future<Skill> get(String agentId, String skillId);
  Future<Skill> add(String agentId, AddSkillRequest req);
  Future<void> delete(String agentId, String skillId);
  Future<Skill> toggle(String agentId, String skillId);
  Future<String> readme(String agentId, String skillId);
  /// 将 skill 从源 Agent 导出到目标 Agent (含文件拷贝)
  Future<Skill> exportToAgent(String sourceAgentId, String skillId, String targetAgentId);
}
