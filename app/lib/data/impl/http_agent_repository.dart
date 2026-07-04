import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/binary_path_resolver.dart';
import '../../core/process_launcher.dart';
import '../models/models.dart';
import '../repositories/agent_repository.dart';

class HttpAgentRepository implements AgentRepository {
  HttpAgentRepository(this._launcher);

  final ProcessLauncher _launcher;

  Future<Uri> _url(String path) async {
    final core = await _launcher.start(binaryPath: BinaryPathResolver.resolve());
    return Uri.parse('http://127.0.0.1:${core.port}$path');
  }

  @override
  Future<List<Agent>> list() async {
    final url = await _url('/agents');
    final res = await _get(url);
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(_parseAgent).toList();
  }

  @override
  Future<Agent> get(String id) async {
    final url = await _url('/agents/$id');
    final j = await _get(url) as Map<String, dynamic>;
    return _parseAgent(j);
  }

  @override
  Future<Agent> create(CreateAgentRequest req) async {
    final url = await _url('/agents');
    final j = await _post(url, {
      'name': req.name,
      'icon': req.icon,
      'iconColor': '#${req.iconColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
      'skillPath': req.skillPath,
      'mcpPath': req.mcpPath,
      'format': req.format.label,
    });
    return _parseAgent(j as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    final url = await _url('/agents/$id');
    final client = HttpClient();
    final req = await client.deleteUrl(url);
    final res = await req.close();
    await res.drain();
    client.close();
  }

  @override
  Future<List<DiscoveredAgent>> scan() async {
    final url = await _url('/agents/scan');
    final j = await _get(url) as Map<String, dynamic>;
    final list = (j['discovered'] as List).cast<Map<String, dynamic>>();
    return list
        .map((m) => DiscoveredAgent(
              type: _formatFromStr(m['type'] as String),
              path: m['path'] as String,
              existing: m['existing'] as bool,
            ))
        .toList();
  }

  AgentFormat _formatFromStr(String s) {
    switch (s) {
      case 'claude-code': return AgentFormat.claudeCode;
      case 'codex': return AgentFormat.codex;
      case 'opencode': return AgentFormat.opencode;
      case 'hermes': return AgentFormat.hermes;
      case 'trae': return AgentFormat.trae;
      case 'zcode': return AgentFormat.zcode;
      case 'workbuddy': return AgentFormat.workbuddy;
      default: return AgentFormat.generic;
    }
  }

  Agent _parseAgent(Map<String, dynamic> j) {
    return Agent(
      id: j['id'] as String,
      name: j['name'] as String,
      icon: j['icon'] as String,
      iconColor: _parseColor(j['iconColor'] as String),
      skillPath: j['skillPath'] as String,
      mcpPath: j['mcpPath'] as String,
      status: _statusFromStr(j['status'] as String),
      format: _formatFromStr(j['format'] as String),
      createdAt: DateTime.tryParse(j['createdAt'] as String) ?? DateTime.now(),
    );
  }

  Color _parseColor(String s) {
    final hex = s.startsWith('#') ? s.substring(1) : s;
    final v = int.tryParse(hex, radix: 16) ?? 0x534AB7;
    if (hex.length == 6) return Color(0xFF000000 | v);
    return Color(v | 0xFF000000);
  }

  AgentStatus _statusFromStr(String s) {
    switch (s) {
      case 'inactive': return AgentStatus.inactive;
      case 'unconfigured': return AgentStatus.unconfigured;
      default: return AgentStatus.active;
    }
  }

  Future<dynamic> _get(Uri url) async {
    final client = HttpClient();
    final req = await client.getUrl(url);
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    client.close();
    return jsonDecode(body);
  }

  Future<dynamic> _post(Uri url, Map<String, dynamic> payload) async {
    final client = HttpClient();
    final req = await client.postUrl(url);
    req.headers.contentType = ContentType.json;
    req.add(utf8.encode(jsonEncode(payload)));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    client.close();
    return jsonDecode(body);
  }
}
