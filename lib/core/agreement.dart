import 'package:shared_preferences/shared_preferences.dart';

/// Aceptación del acuerdo de licencia (textos en assets/i18n/app.json, `licenseBody`; el LICENSE del repo dice lo mismo).
class Agreement {
  /// Subirlo cuando cambie el texto del acuerdo: quien aceptó una versión anterior lo vuelve a ver al abrir la app.
  static const version = 1;
  static const key = 'licenseAccepted';

  late SharedPreferences _prefs;

  void load(SharedPreferences prefs) => _prefs = prefs;

  bool get accepted => (_prefs.getInt(key) ?? 0) >= version;

  Future<void> accept() => _prefs.setInt(key, version);
}
