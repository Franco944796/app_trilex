import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'util.dart';

class Content {
  /// Sitio publicado (GitHub Pages). Cambiarlo aquí si la web se muda.
  static const siteUrl = 'https://franco944796.github.io/beta-idiomas/';
  static const baseUrl = '${siteUrl}content/en/';

  late Directory _dir;
  Map<String, String> _bundled = {}; // manifest de la app: {ruta: hash}
  String _bundledVersion = '';
  Map<String, String> _remote = {};
  Set<String> _downloaded = {};
  String version = '';
  final _cache = <String, dynamic>{};

  Future<void> init() async {
    final base = await getApplicationSupportDirectory();
    _dir = Directory('${base.path}/content/en');
    final b = jsonDecode(await rootBundle.loadString('assets/content/en/manifest.json')) as Json;
    _bundled = (b['files'] as Map).cast<String, String>();
    version = _bundledVersion = str(b['version']);
    final local = File('${_dir.path}/manifest.json');
    if (await local.exists()) {
      try {
        final m = jsonDecode(await local.readAsString()) as Json;
        if (str(m['base']) != _bundledVersion) {
          // la app se actualizó con otro contenido: la copia descargada quedó vieja
          await _dir.delete(recursive: true);
          return;
        }
        _remote = (m['files'] as Map).cast<String, String>();
        _downloaded = strList(m['downloaded']).toSet();
        version = str(m['version']);
      } catch (_) {
        _downloaded = {};
      }
    }
  }

  Future<dynamic> json(String path) async {
    final hit = _cache[path];
    if (hit != null) return hit;
    String text;
    final f = File('${_dir.path}/$path');
    if (_downloaded.contains(path) && await f.exists()) {
      text = await f.readAsString();
    } else {
      text = await rootBundle.loadString('assets/content/en/$path');
    }
    final v = joinLines(jsonDecode(text));
    _cache[path] = v;
    return v;
  }

  Future<Json> obj(String path) async => (await json(path) as Map).cast<String, dynamic>();

  /// Busca contenido nuevo en la web. Devuelve cuántos archivos se descargaron
  /// (0 = ya estaba al día). Lanza una excepción si no hay conexión.
  Future<int> update() async {
    final res = await http.get(Uri.parse('${baseUrl}manifest.json')).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw HttpException('manifest ${res.statusCode}');
    final m = jsonDecode(utf8.decode(res.bodyBytes)) as Json;
    if (str(m['version']) == version) return 0;
    final files = (m['files'] as Map).cast<String, String>();
    String? have(String p) => _downloaded.contains(p) ? _remote[p] : _bundled[p];
    final todo = [for (final e in files.entries) if (have(e.key) != e.value) e.key];
    final got = {for (final p in _downloaded) if (files[p] != null && have(p) == files[p]) p};
    for (final path in todo) {
      final r = await http.get(Uri.parse(baseUrl + path)).timeout(const Duration(seconds: 30));
      if (r.statusCode != 200) throw HttpException('$path ${r.statusCode}');
      final f = File('${_dir.path}/$path');
      await f.parent.create(recursive: true);
      await f.writeAsBytes(r.bodyBytes);
      got.add(path);
    }
    await _dir.create(recursive: true);
    await File('${_dir.path}/manifest.json').writeAsString(jsonEncode({
      'version': m['version'],
      'base': _bundledVersion,
      'files': files,
      'downloaded': got.toList()..sort(),
    }));
    _remote = files;
    _downloaded = got;
    version = str(m['version']);
    _cache.clear();
    return todo.length;
  }
}
