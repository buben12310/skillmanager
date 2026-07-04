// 对照 DESIGN_SPEC §8 数据模型
import 'package:flutter/material.dart';

enum AgentFormat { claudeCode, codex, opencode, hermes, trae, zcode, workbuddy, generic }

enum AgentStatus { active, inactive, unconfigured }

extension AgentFormatX on AgentFormat {
  String get label {
    switch (this) {
      case AgentFormat.claudeCode: return 'claude-code';
      case AgentFormat.codex: return 'codex';
      case AgentFormat.opencode: return 'opencode';
      case AgentFormat.hermes: return 'hermes';
      case AgentFormat.trae: return 'trae';
      case AgentFormat.zcode: return 'zcode';
      case AgentFormat.workbuddy: return 'workbuddy';
      case AgentFormat.generic: return 'generic';
    }
  }
}

class Agent {
  final String id;
  final String name;
  final String icon;
  final Color iconColor;
  final String skillPath;
  final String mcpPath;
  final AgentStatus status;
  final AgentFormat format;
  final DateTime createdAt;

  Agent({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.skillPath,
    required this.mcpPath,
    required this.status,
    required this.format,
    required this.createdAt,
  });

  factory Agent.mock({
    required String id,
    required String name,
    required String icon,
    required Color iconColor,
    required String skillPath,
    required String mcpPath,
    required AgentFormat format,
    AgentStatus status = AgentStatus.active,
  }) =>
      Agent(
        id: id,
        name: name,
        icon: icon,
        iconColor: iconColor,
        skillPath: skillPath,
        mcpPath: mcpPath,
        status: status,
        format: format,
        createdAt: DateTime(2026, 6, 22),
      );
}

enum SkillSource { marketplace, local, builtin, import }

class Skill {
  final String id;
  final String agentId;
  final String name;
  final String? version;
  final String? author;
  final SkillSource source;
  final String? sourceUrl;
  final String path;
  final bool enabled;
  final AgentFormat format;
  final List<String> dependencies;
  final DateTime installedAt;

  Skill({
    required this.id,
    required this.agentId,
    required this.name,
    this.version,
    this.author,
    required this.source,
    this.sourceUrl,
    required this.path,
    required this.enabled,
    required this.format,
    required this.dependencies,
    required this.installedAt,
  });

  Skill copyWith({bool? enabled}) => Skill(
        id: id,
        agentId: agentId,
        name: name,
        version: version,
        author: author,
        source: source,
        sourceUrl: sourceUrl,
        path: path,
        enabled: enabled ?? this.enabled,
        format: format,
        dependencies: dependencies,
        installedAt: installedAt,
      );
}

class Mcp {
  final String id;
  final String agentId;
  final String name;
  final String command;
  final List<String> args;
  final String path;
  final bool connected;
  final List<String> tools;
  final DateTime? lastTestedAt;

  Mcp({
    required this.id,
    required this.agentId,
    required this.name,
    required this.command,
    required this.args,
    required this.path,
    required this.connected,
    required this.tools,
    this.lastTestedAt,
  });

  Mcp copyWith({bool? connected, List<String>? tools, DateTime? lastTestedAt}) => Mcp(
        id: id,
        agentId: agentId,
        name: name,
        command: command,
        args: args,
        path: path,
        connected: connected ?? this.connected,
        tools: tools ?? this.tools,
        lastTestedAt: lastTestedAt ?? this.lastTestedAt,
      );
}

// 仓库 (市场条目)
class MarketplaceRepo {
  final String owner;
  final String name;
  final String description;
  final int stars;
  final String? license;
  final String? defaultBranch;
  final List<String> topics;

  MarketplaceRepo({
    required this.owner,
    required this.name,
    required this.description,
    required this.stars,
    this.license,
    this.defaultBranch,
    required this.topics,
  });

  String get fullName => '$owner/$name';
}
