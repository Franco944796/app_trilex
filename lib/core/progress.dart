import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'util.dart';

/// Progreso guardado solo en el teléfono, con el mismo formato que la web:
/// el curso en 'trilex_en_v1' y la lectura en 'trilex_read_v1'.
class Progress extends ChangeNotifier {
  static const courseKey = 'trilex_en_v1', readKey = 'trilex_read_v1';
  late SharedPreferences _prefs;

  /// Curso: done {id: {score, at}}, srs {id: {box, due, lapses}}, exams {A1: {pct, passed, at}},
  /// placement {level, passed, scores, at}, open (modo prueba), secs {día: segundos}, goal (min).
  Json course = {};

  /// Lectura: t {texto: {best, last, at}}, b {libro: {c: {n: {best, at}}, last, pos}}, words [],
  /// drafts {}, notes {id: {title, href, level, general, marks: []}}, size, rate.
  Json reading = {};

  /// Recordatorio diario: activado y hora (minutos desde las 0:00).
  bool reminderOn = false;
  int reminderAt = 19 * 60;

  static Json freshCourse([int goal = 20]) => {
        'done': <String, dynamic>{},
        'srs': <String, dynamic>{},
        'exams': <String, dynamic>{},
        'placement': null,
        'open': false,
        'secs': <String, dynamic>{},
        'goal': goal,
      };

  static Json freshReading() => {
        't': <String, dynamic>{},
        'b': <String, dynamic>{},
        'words': <dynamic>[],
        'drafts': <String, dynamic>{},
        'notes': <String, dynamic>{},
        'size': 1.0,
        'rate': 0.9,
      };

  Future<void> load(SharedPreferences prefs) async {
    _prefs = prefs;
    course = {...freshCourse(), ..._read(courseKey)};
    reading = {...freshReading(), ..._read(readKey)};
    reminderOn = prefs.getBool('reminderOn') ?? false;
    reminderAt = prefs.getInt('reminderAt') ?? 19 * 60;
  }

  Json _read(String key) {
    try {
      final s = _prefs.getString(key);
      if (s != null) return (jsonDecode(s) as Map).cast<String, dynamic>();
    } catch (_) {}
    return {};
  }

  Future<void> save() async {
    await _prefs.setString(courseKey, jsonEncode(course));
    await _prefs.setString(readKey, jsonEncode(reading));
    await _prefs.setBool('reminderOn', reminderOn);
    await _prefs.setInt('reminderAt', reminderAt);
    notifyListeners();
  }

  Json _map(Json parent, String k) {
    final v = parent[k];
    if (v is Map<String, dynamic>) return v;
    final m = v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};
    parent[k] = m;
    return m;
  }

  Json get done => _map(course, 'done');
  Json get srs => _map(course, 'srs');
  Json get exams => _map(course, 'exams');
  Json get secs => _map(course, 'secs');
  Json? get placement => course['placement'] is Map ? (course['placement'] as Map).cast<String, dynamic>() : null;
  bool get testMode => course['open'] == true;
  int get goal => (course['goal'] as num?)?.toInt() ?? 20;

  Json get texts => _map(reading, 't');
  Json get books => _map(reading, 'b');
  Json get drafts => _map(reading, 'drafts');
  Json get notes => _map(reading, 'notes');
  List<dynamic> get words {
    final w = reading['words'];
    if (w is List) return w;
    return reading['words'] = <dynamic>[];
  }

  /// Plan de «Hoy»: qué partes se hicieron cada día ({día: ['read', 'review', 'produce']}).
  /// Solo se guardan los últimos 60 días.
  Json get daily => _map(reading, 'daily');

  bool doneToday(String part) => strList(daily[dayKey(DateTime.now())]).contains(part);

  void markToday(String part) {
    final k = dayKey(DateTime.now());
    final l = strList(daily[k]);
    if (l.contains(part)) return;
    daily[k] = [...l, part];
    final keep = (daily.keys.toList()..sort()).reversed.take(60).toSet();
    daily.removeWhere((key, _) => !keep.contains(key));
    save();
  }

  /// Listas «puedo…» de cada nivel: {B1: [índices marcados]}.
  Json get canDo => _map(reading, 'cando');

  double get textSize => (reading['size'] as num?)?.toDouble() ?? 1.0;
  double get rate => (reading['rate'] as num?)?.toDouble() ?? 0.9;

  int _lastAct = 0, _lastSave = 0;

  /// Suma el tiempo entre interacciones (las pausas de más de 2 minutos no cuentan).
  void tick() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastAct > 0 && now - _lastAct < 120000) {
      final k = dayKey(DateTime.now());
      secs[k] = ((secs[k] as num?) ?? 0) + (now - _lastAct) / 1000;
      if (now - _lastSave > 5000) {
        _lastSave = now;
        _prefs.setString(courseKey, jsonEncode(course));
      }
    }
    _lastAct = now;
  }

  int get minutesToday => (((secs[dayKey(DateTime.now())] as num?) ?? 0) / 60).floor();

  /// Días seguidos cumpliendo la meta (si hoy aún no, cuenta desde ayer).
  int get streak {
    bool ok(DateTime d) => ((secs[dayKey(d)] as num?) ?? 0) >= goal * 60;
    var d = DateTime.now();
    var n = 0;
    if (!ok(d)) d = d.subtract(const Duration(days: 1));
    while (ok(d)) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  Future<void> resetCourse() async {
    course = freshCourse(goal);
    await save();
  }

  Future<void> resetReading() async {
    reading = freshReading();
    await save();
  }
}
