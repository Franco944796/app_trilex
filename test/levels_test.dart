import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trilex/core/progress.dart';
import 'package:trilex/core/services.dart';
import 'package:trilex/course/course.dart';
import 'package:trilex/course/grammar_screen.dart';
import 'package:trilex/ui/theme.dart';

/// Carga el progreso con [placement] (null = sin prueba) y, si [examB1], el examen B1 aprobado.
Future<void> _setUp(WidgetTester tester, {List<String>? placement, bool examB1 = false}) async {
  tester.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  final c = <String, dynamic>{
    if (placement != null) 'placement': {'level': placement.isEmpty ? 'A2' : placement.last, 'passed': placement},
    if (examB1) 'exams': {'B1': {'pct': 0.8, 'passed': true}},
  };
  SharedPreferences.setMockInitialValues({'selectedLanguage': 'es', Progress.courseKey: jsonEncode(c)});
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'), (c) async => Directory.systemTemp.createTempSync('trx').path);
  await tester.runAsync(() async {
    final p = await SharedPreferences.getInstance();
    await i18n.load(p);
    await progress.load(p);
    await content.init();
    await course.load();
  });
  Tx.use(Brightness.light);
}

void main() {
  testWidgets('sin prueba de nivel: B1 abierto, B2 cerrado', (tester) async {
    await _setUp(tester);
    expect(course.unlocked('B1'), isTrue);
    expect(course.unlocked('B2'), isFalse);
  });

  testWidgets('prueba en B1: B2 cerrado hasta aprobar el examen B1', (tester) async {
    await _setUp(tester, placement: ['B1']);
    expect(course.unlocked('B1'), isTrue);
    expect(course.unlocked('B2'), isFalse);
    await _setUp(tester, placement: ['B1'], examB1: true);
    expect(course.unlocked('B2'), isTrue);
  });

  testWidgets('prueba en B2: todo abierto', (tester) async {
    await _setUp(tester, placement: ['B1', 'B2']);
    expect(course.unlocked('B1'), isTrue);
    expect(course.unlocked('B2'), isTrue);
  });

  testWidgets('menos de B1: los dos cerrados, aunque haya un examen B1 viejo aprobado', (tester) async {
    await _setUp(tester, placement: [], examB1: true);
    expect(course.unlocked('B1'), isFalse);
    expect(course.unlocked('B2'), isFalse);
  });

  testWidgets('Gramática muestra el candado y cómo desbloquear B2', (tester) async {
    await _setUp(tester, placement: ['B1']);
    await tester.pumpWidget(MaterialApp(theme: Tx.theme(), home: const Scaffold(body: GrammarScreen())));
    await tester.pump();
    expect(find.text('🔒 B2'), findsOneWidget);
    expect(find.text('B1'), findsOneWidget);
    await tester.ensureVisible(find.text('🔒 B2'));
    await tester.pump();
    await tester.tap(find.text('🔒 B2'));
    await tester.pump();
    expect(find.text(tr('grLockB2')), findsOneWidget);
    expect(find.text(tr('takeExam')), findsNothing, reason: 'B2 cerrado: no se ve su examen');
  });

  testWidgets('menos de B1: Gramática recomienda la web', (tester) async {
    await _setUp(tester, placement: []);
    await tester.pumpWidget(MaterialApp(theme: Tx.theme(), home: const Scaffold(body: GrammarScreen())));
    await tester.pump();
    expect(find.text(tr('grLockB1')), findsOneWidget, reason: 'B1 se abre de entrada y muestra el aviso');
    expect(find.text(tr('openWeb')), findsOneWidget);
  });
}
