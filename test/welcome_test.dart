import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trilex/core/services.dart';
import 'package:trilex/course/course.dart';
import 'package:trilex/main.dart';
import 'package:trilex/welcome_screen.dart';

Future<SharedPreferences> _setUp(WidgetTester tester, Map<String, Object> values) async {
  tester.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(values);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'), (c) async => Directory.systemTemp.createTempSync('trx').path);
  final prefs = (await tester.runAsync(() async {
    final p = await SharedPreferences.getInstance();
    await i18n.load(p);
    themePref.load(p);
    await progress.load(p);
    await content.init();
    await course.load();
    return p;
  }))!;
  return prefs;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 5)));
    await tester.pump();
  }
}

void main() {
  testWidgets('la primera vez se elige el idioma, que se aplica al tocarlo y queda guardado', (tester) async {
    final prefs = await _setUp(tester, {});
    await tester.pumpWidget(const TrilexApp());
    await _settle(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.text('🇩🇪 Deutsch'));
    await _settle(tester);
    expect(find.text('Wählen Sie Ihre Sprache'), findsOneWidget);

    await tester.tap(find.text('Starten'));
    await _settle(tester);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(prefs.getString('selectedLanguage'), 'de');
  });

  testWidgets('el idioma detectado también queda guardado si se toca «Empezar» sin cambiarlo', (tester) async {
    final prefs = await _setUp(tester, {});
    await tester.pumpWidget(const TrilexApp());
    await _settle(tester);
    await tester.tap(find.byType(FilledButton));
    await _settle(tester);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(prefs.getString('selectedLanguage'), i18n.lang);
  });

  testWidgets('con un idioma ya elegido no se pregunta', (tester) async {
    await _setUp(tester, {'selectedLanguage': 'es'});
    await tester.pumpWidget(const TrilexApp());
    await _settle(tester);
    expect(find.byType(WelcomeScreen), findsNothing);
  });
}
