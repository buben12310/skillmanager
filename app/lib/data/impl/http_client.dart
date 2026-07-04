import 'dart:convert';
import 'dart:io';
import '../../core/binary_path_resolver.dart';
import '../../core/process_launcher.dart';

class HttpClientHelper {
  HttpClientHelper(this._launcher);
  final ProcessLauncher _launcher;

  Future<Uri> url(String path) async {
    final core = await _launcher.start(binaryPath: BinaryPathResolver.resolve());
    return Uri.parse('http://127.0.0.1:${core.port}$path');
  }

  Future<dynamic> get(String path) async => _send('GET', path, null);

  Future<dynamic> post(String path, Map<String, dynamic> payload) async =>
      _send('POST', path, payload);

  Future<void> delete(String path) async => _send('DELETE', path, null);

  Future<dynamic> send(String method, String path) async =>
      _send(method.toUpperCase(), path, null);

  Future<dynamic> _send(String method, String path, Map<String, dynamic>? payload) async {
    final u = await url(path);
    final c = HttpClient();
    final r = await c.openUrl(method, u);
    if (payload != null) {
      r.headers.contentType = ContentType.json;
      r.add(utf8.encode(jsonEncode(payload)));
    }
    final res = await r.close();
    final body = await res.transform(utf8.decoder).join();
    c.close();
    // 非 2xx 视为错误,优先提取后端返回的 message
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String message = 'HTTP ${res.statusCode}';
      if (body.isNotEmpty) {
        try {
          final j = jsonDecode(body);
          if (j is Map<String, dynamic>) {
            final m = j['message'] ?? j['error'] ?? j['code'];
            if (m != null) message = '$m';
          }
        } catch (_) {
          message = body;
        }
      }
      throw Exception(message);
    }
    if (body.isEmpty) return {};
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }
}
