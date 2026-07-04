import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';

sealed class DetailEntry {}

class AgentEntry extends DetailEntry {
  final Agent agent;
  AgentEntry(this.agent);
}

class SkillEntry extends DetailEntry {
  final Agent agent;
  final Skill skill;
  SkillEntry(this.agent, this.skill);
}

class McpEntry extends DetailEntry {
  final Agent agent;
  final Mcp mcp;
  McpEntry(this.agent, this.mcp);
}

class DetailStackNotifier extends StateNotifier<List<DetailEntry>> {
  DetailStackNotifier() : super(const []);

  void pushAgent(Agent a) => state = [...state, AgentEntry(a)];
  void pushSkill(Agent a, Skill s) => state = [...state, SkillEntry(a, s)];
  void pushMcp(Agent a, Mcp m) => state = [...state, McpEntry(a, m)];
  void pop() =>
      state = state.isEmpty ? state : state.sublist(0, state.length - 1);
  void clear() => state = const [];
}

final detailStackProvider =
    StateNotifierProvider<DetailStackNotifier, List<DetailEntry>>(
        (ref) => DetailStackNotifier());
