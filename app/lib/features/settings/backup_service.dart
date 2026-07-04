// 全量数据备份:遍历所有 agent → skills + mcps → 打包 zip 到指定目录
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../core/providers.dart';
import '../../data/models/models.dart';

class BackupService {
  BackupService(this._ref);
  final Ref _ref;

  /// 导出全部数据。返回生成的 zip 文件路径。
  Future<String> exportAll() async {
    final dir = await FilePicker.platform
        .getDirectoryPath(dialogTitle: '选择备份文件保存目录');
    if (dir == null) throw Exception('取消选择');

    final now = DateTime.now();
    final stamp = _stamp(now);
    final zipPath = p.join(dir, 'skillmanager-backup-$stamp.zip');

    final archive = Archive();
    final agents = await _ref.read(agentRepositoryProvider).list();
    final skillRepo = _ref.read(skillRepositoryProvider);
    final mcpRepo = _ref.read(mcpRepositoryProvider);

    // 1. agents.json
    final agentsJson = agents
        .map((a) => {
              'id': a.id,
              'name': a.name,
              'icon': a.icon,
              'iconColor': a.iconColor.toARGB32(),
              'skillPath': a.skillPath,
              'mcpPath': a.mcpPath,
              'format': a.format.label,
              'status': a.status.name,
              'createdAt': a.createdAt.toIso8601String(),
            })
        .toList();
    _addJson(archive, 'agents.json', agentsJson);

    // 2. 每个 agent 的 skills + mcps
    final allSkills = <Map<String, dynamic>>[];
    final allMcps = <Map<String, dynamic>>[];
    for (final a in agents) {
      final skills = await skillRepo.listByAgent(a.id);
      for (final s in skills) {
        allSkills.add({
          'id': s.id,
          'agentId': s.agentId,
          'name': s.name,
          'version': s.version,
          'author': s.author,
          'source': s.source.name,
          'sourceUrl': s.sourceUrl,
          'path': s.path,
          'enabled': s.enabled,
          'format': s.format.label,
          'dependencies': s.dependencies,
          'installedAt': s.installedAt.toIso8601String(),
        });
        // 把 skill 文件目录打包进 zip
        _packDir(archive, s.path, 'skills/${s.name}/');
      }
      final mcps = await mcpRepo.listByAgent(a.id);
      for (final m in mcps) {
        allMcps.add({
          'id': m.id,
          'agentId': m.agentId,
          'name': m.name,
          'command': m.command,
          'args': m.args,
          'path': m.path,
          'connected': m.connected,
          'tools': m.tools,
          'lastTestedAt': m.lastTestedAt?.toIso8601String(),
        });
      }
    }
    _addJson(archive, 'skills.json', allSkills);
    _addJson(archive, 'mcps.json', allMcps);
    _addJson(archive, 'manifest.json', {
      'version': '1.0.0',
      'createdAt': now.toIso8601String(),
      'agentCount': agents.length,
      'skillCount': allSkills.length,
      'mcpCount': allMcps.length,
    });

    final zipBytes = ZipEncoder().encode(archive)!;
    await File(zipPath).writeAsBytes(zipBytes);
    return zipPath;
  }

  void _addJson(Archive archive, String name, Object data) {
    final str = const JsonEncoder.withIndent('  ').convert(data);
    archive.addFile(ArchiveFile(name, str.length, str));
  }

  void _packDir(Archive archive, String dirPath, String prefix) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;
    _walk(dir, archive, prefix);
  }

  void _walk(Directory dir, Archive archive, String prefix) {
    for (final e in dir.listSync()) {
      final name = p.basename(e.path);
      if (e is File) {
        final bytes = e.readAsBytesSync();
        archive.addFile(ArchiveFile('$prefix$name', bytes.length, bytes));
      } else if (e is Directory) {
        _walk(e, archive, '$prefix$name/');
      }
    }
  }

  String _stamp(DateTime t) =>
      '${t.year}${t.month.toString().padLeft(2, '0')}${t.day.toString().padLeft(2, '0')}-'
      '${t.hour.toString().padLeft(2, '0')}${t.minute.toString().padLeft(2, '0')}${t.second.toString().padLeft(2, '0')}';
}

final backupServiceProvider = Provider<BackupService>((ref) => BackupService(ref));
