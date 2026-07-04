// Go core 二进制路径解析器
// 支持 dev 和 release 两种模式
import 'dart:io';
import 'package:path/path.dart' as p;

class BinaryPathResolver {
  BinaryPathResolver._();

  /// 解析 Go core 二进制路径
  /// 优先级:
  /// 1. 与当前 exe 同目录 (release 模式)
  /// 2. ../skillmanager-core/ (dev 模式)
  /// 3. assets/bin/ (旧模式)
  static String resolve() {
    const exeName = 'skillmanager-core.exe';

    // 候选路径列表
    final candidates = <String>[
      // 1. release 模式: 与 exe 同目录
      p.join(p.dirname(Platform.resolvedExecutable), exeName),
      // 2. dev 模式: 项目根 skillmanager-core/
      p.join(p.dirname(Platform.resolvedExecutable), '..', 'skillmanager-core', exeName),
      // 3. dev 模式回退: app 根目录上一级
      p.join(p.current, '..', 'skillmanager-core', exeName),
      // 4. assets/bin 回退 (旧模式)
      p.join(p.current, 'assets', 'bin', exeName),
    ];

    for (final path in candidates) {
      final normalized = p.normalize(path);
      if (File(normalized).existsSync()) {
        return normalized;
      }
    }

    // 默认返回 dev 路径
    return p.normalize(p.join(p.dirname(Platform.resolvedExecutable), '..', 'skillmanager-core', exeName));
  }
}
