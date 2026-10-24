import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// Textos de la interfaz en 8 idiomas. Son los mismos de la web (assets/i18n/ui.json, generado
/// por tools/app_sync.py a partir de ingles/trilex-i18n*.js) más los propios de la app
/// (assets/i18n/app.json). Cada clave: [en, es, fr, de, it, pt, ru, zh].
class I18n extends ChangeNotifier {
  static const langs = ['en', 'es', 'fr', 'de', 'it', 'pt', 'ru', 'zh'];
  static const names = {
    'en': '🇬🇧 English',
    'es': '🇪🇸 Español',
    'fr': '🇫🇷 Français',
    'de': '🇩🇪 Deutsch',
    'it': '🇮🇹 Italiano',
    'pt': '🇵🇹 Português',
    'ru': '🇷🇺 Русский',
    'zh': '🇨🇳 中文',
  };

  final _keys = <String, List<String>>{};
  final _topics = <String, List<String>>{};
  final _faq = <String, List<List<String>>>{};
  late SharedPreferences _prefs;
  String lang = 'es';

  int get _ix => langs.indexOf(lang);
  bool get isEs => lang == 'es';

  Future<void> load(SharedPreferences prefs) async {
    _prefs = prefs;
    final ui = jsonDecode(await rootBundle.loadString('assets/i18n/ui.json')) as Map<String, dynamic>;
    final app = jsonDecode(await rootBundle.loadString('assets/i18n/app.json')) as Map<String, dynamic>;
    for (final src in [ui['keys'] as Map<String, dynamic>, app]) {
      src.forEach((k, v) {
        if (v is List) _keys[k] = v.map((e) => '$e').toList();
      });
    }
    (ui['topics'] as Map<String, dynamic>).forEach((k, v) => _topics[k] = (v as List).map((e) => '$e').toList());
    (ui['faq'] as Map<String, dynamic>).forEach((lg, list) {
      _faq[lg] = [for (final qa in list as List) (qa as List).map((e) => '$e').toList()];
    });
    final saved = prefs.getString('selectedLanguage');
    final sys = PlatformDispatcher.instance.locale.languageCode;
    lang = langs.contains(saved) ? saved! : (langs.contains(sys) ? sys : 'en');
  }

  /// Texto de una clave con variables {n}, {l}…
  String t(String key, [Map<String, Object?> vars = const {}]) {
    final row = _keys[key];
    var s = row == null ? key : (row[_ix].isEmpty ? row[0] : row[_ix]);
    vars.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }

  String topic(String s) => _topics[s]?[_ix] ?? s;

  List<List<String>> get faq => _faq[lang] ?? _faq['es'] ?? const [];

  /// Vuelve a dibujar la interfaz (por ejemplo, después de cargar contenido nuevo).
  void refresh() => notifyListeners();

  Future<void> setLang(String l) async {
    if (!langs.contains(l) || l == lang) return;
    lang = l;
    await _prefs.setString('selectedLanguage', l);
    notifyListeners();
  }
}
