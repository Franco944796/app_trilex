import 'content.dart';
import 'i18n.dart';
import 'progress.dart';
import 'reminders.dart';
import 'speech.dart';
import 'theme_pref.dart';

final i18n = I18n();
final content = Content();
final progress = Progress();
final speech = Speech();
final reminders = Reminders();
final themePref = ThemePref();

String tr(String key, [Map<String, Object?> vars = const {}]) => i18n.t(key, vars);
