// 路径展开工具: 统一处理 ~ 前缀和路径规范化
import 'dart:io';
import 'package:path/path.dart' as p;

class PathExpander {
  PathExpander._();

  /// 展开 ~ 为用户主目录,规范化路径
  /// 支持 ~/xxx, ~, 以及绝对/相对路径
  static String expand(String raw) {
    if (raw.isEmpty) return raw;
    var path = raw;
    if (path.startsWith('~/') || path == '~') {
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
      if (path == '~') {
        path = home;
      } else {
        path = p.join(home, path.substring(2));
      }
    }
    return p.normalize(path);
  }

  /// 检查路径是否存在 (文件或目录)
  static bool exists(String raw) {
    final expanded = expand(raw);
    return FileSystemEntity.typeSync(expanded) != FileSystemEntityType.notFound;
  }

  /// 检查是否为目录
  static bool isDirectory(String raw) {
    final expanded = expand(raw);
    return FileSystemEntity.isDirectorySync(expanded);
  }

  /// 检查是否为文件
  static bool isFile(String raw) {
    final expanded = expand(raw);
    return FileSystemEntity.isFileSync(expanded);
  }
}
