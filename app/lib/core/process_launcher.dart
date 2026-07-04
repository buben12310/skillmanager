import 'dart:convert';
import 'dart:io';

class CoreProcess {
  final int port;
  final int pid;
  final String version;
  CoreProcess({required this.port, required this.pid, required this.version});

  factory CoreProcess.fromJson(Map<String, dynamic> j) => CoreProcess(
        port: j['port'] as int,
        pid: j['pid'] as int,
        version: j['version'] as String,
      );
}

class ProcessLauncher {
  Process? _process;
  CoreProcess? _core;

  CoreProcess? get core => _core;

  /// 拉起 Go 子进程并解析握手
  Future<CoreProcess> start({required String binaryPath}) async {
    if (_core != null) return _core!;
    final proc = await Process.start(
      binaryPath,
      ['-addr', '127.0.0.1:0'],
    );
    _process = proc;
    // 读第一行 JSON 握手
    final line = await proc.stdout.first;
    final json = jsonDecode(utf8.decode(line)) as Map<String, dynamic>;
    _core = CoreProcess.fromJson(json);
    // stderr 后台打印
    proc.stderr.listen((_) {}); // 静默
    return _core!;
  }

  Future<void> stop() async {
    if (_core != null) {
      try {
        final client = HttpClient();
        final req = await client.getUrl(Uri.parse('http://127.0.0.1:${_core!.port}/shutdown'));
        await req.close();
        client.close();
      } catch (_) {}
    }
    _process?.kill();
    _process = null;
    _core = null;
  }
}
