// 对照 DEVELOPMENT_PLAN §1.6 接口预留
import 'package:flutter/material.dart';
import '../models/models.dart';

class DiscoveredAgent {
  final AgentFormat type;
  final String path;
  final bool existing;
  DiscoveredAgent({required this.type, required this.path, required this.existing});
}

class CreateAgentRequest {
  final String name;
  final String icon;
  final Color iconColor;
  final String skillPath;
  final String mcpPath;
  final AgentFormat format;
  CreateAgentRequest({
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.skillPath,
    required this.mcpPath,
    required this.format,
  });
}

abstract class AgentRepository {
  Future<List<Agent>> list();
  Future<Agent> get(String id);
  Future<Agent> create(CreateAgentRequest req);
  Future<void> delete(String id);
  Future<List<DiscoveredAgent>> scan(); // ← Phase 2 接 Go Scanner
}
