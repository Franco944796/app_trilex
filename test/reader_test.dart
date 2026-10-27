import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trilex/core/services.dart';
import 'package:trilex/core/progress.dart';
import 'package:trilex/core/util.dart';
import 'package:trilex/course/course.dart';
import 'package:trilex/reading/reader_screen.dart';
import 'package:trilex/ui/theme.dart';

Future<void> _setUp(WidgetTester tester, [Map<String, Object> prefs = const {}]) async {
  tester.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'selectedLanguage': 'es', ...prefs});
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'), (c) async => Directory.systemTemp.createTempSync('trx').path);
  await tester.runAsync(() async {
    final p = await SharedPreferences.getInstance();
    await i18n.load(p);
    themePref.load(p);
    await progress.load(p);
    await content.init();
    await course.load();
  });
  Tx.use(Brightness.light);
}

/// Abre el lector y espera a que termine de cargar (la carga usa otro hilo: hace falta tiempo real).
Future<void> _open(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(MaterialApp(theme: Tx.theme(), home: screen));
  for (var i = 0; i < 400 && find.text('A+').evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 5)));
    await tester.pump();
  }
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 5)));
    await tester.pump();
  }
}

Finder _para(String text, {bool skipOffstage = true}) => find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText().startsWith(text.substring(0, 30)),
    skipOffstage: skipOffstage).first; // la primera oración se repite más abajo, en «escuchar y repetir»

/// Lleva el párrafo arriba de la pantalla (arriba del texto está el glosario abierto).
Future<void> _toTop(WidgetTester tester, String text) async {
  await tester.ensureVisible(_para(text, skipOffstage: false));
  await tester.pump();
  await tester.drag(find.byType(Scrollable).first, Offset(0, 80 - tester.getRect(_para(text)).top));
  await tester.pump();
}

void main() {
  testWidgets('mantener presionado y arrastrar selecciona varios párrafos y los subraya', (tester) async {
    await _setUp(tester);
    await _open(tester, const ReaderScreen.text('b1-coffee'));
    final t = await tester.runAsync(() => content.obj('reading/texts/b1-coffee.json'));
    final paras = strList(t!['paragraphs']);
    await _toTop(tester, paras[0]);

    final first = tester.getRect(_para(paras[0]));
    final second = tester.getRect(_para(paras[1]));
    final g = await tester.startGesture(first.topLeft + const Offset(4, 12));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await g.moveTo(second.center);
    await tester.pump();
    expect(find.byIcon(Icons.close), findsNothing, reason: 'la barra aparece al soltar');
    await g.up();
    await tester.pump();

    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.text(tr('copyW')), findsOneWidget);
    expect(find.text(tr('translateW')), findsNothing, reason: 'traducir es solo para frases cortas de un párrafo');

    await tester.tap(find.byWidgetPredicate((w) => w is InkWell && w.customBorder is CircleBorder).first);
    await tester.pump();
    final marks = (progress.notes['t:b1-coffee'] as Map)['marks'] as List;
    expect(marks, hasLength(1));
    final ranges = (marks.first as Map)['ranges'] as List;
    expect(ranges.map((r) => (r as Map)['p']), [0, 1]);
    expect((ranges.first as Map)['s'], 0);
    expect(str((marks.first as Map)['quote']), startsWith('Every day,'));
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('con una selección abierta, tocar el texto solo la quita', (tester) async {
    await _setUp(tester);
    await _open(tester, const ReaderScreen.text('b1-coffee'));
    final t = await tester.runAsync(() => content.obj('reading/texts/b1-coffee.json'));
    await _toTop(tester, strList(t!['paragraphs'])[0]);
    final first = tester.getRect(_para(strList(t['paragraphs'])[0]));
    await tester.longPressAt(first.topLeft + const Offset(4, 12));
    await tester.pump();
    expect(find.text(tr('translateW')), findsOneWidget, reason: 'una sola palabra se puede traducir');
    await tester.tapAt(first.center);
    await tester.pump();
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byType(BottomSheet), findsNothing, reason: 'no abre el diccionario');
  });

  testWidgets('arrastrar hasta el borde de abajo desplaza el texto y sigue seleccionando', (tester) async {
    await _setUp(tester);
    await _open(tester, const ReaderScreen.chapter('sherlock-holmes', 12));
    final c = await tester.runAsync(() => content.obj('reading/books/sherlock-holmes/ch-12.json'));
    final blocks = jsonList(c!['blocks']);
    await _toTop(tester, str(blocks[0]['text']));
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    final before = scroll.pixels;
    final g = await tester.startGesture(tester.getRect(_para(str(blocks[0]['text']))).topLeft + const Offset(4, 12));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await g.moveTo(const Offset(200, 600));
    await g.moveTo(const Offset(200, 905));
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pump();
    expect(scroll.pixels, greaterThan(before + 600));
    await tester.tap(find.byWidgetPredicate((w) => w is InkWell && w.customBorder is CircleBorder).first);
    await tester.pump();
    final ranges = ((progress.notes['b:sherlock-holmes:12'] as Map)['marks'] as List).first['ranges'] as List;
    expect(ranges.first['p'], 0);
    expect(ranges.length, greaterThanOrEqualTo(4), reason: 'la selección siguió al texto desplazado');
    expect(ranges.map((r) => r['p']), List.generate(ranges.length, (i) => i));
  });

  testWidgets('el libro vuelve al párrafo donde se dejó, aunque la lista sea perezosa', (tester) async {
    await _setUp(tester, {
      Progress.readKey: '{"b":{"sherlock-holmes":{"c":{},"pos":{"12":120}}}}',
    });
    await _open(tester, const ReaderScreen.chapter('sherlock-holmes', 12));
    final c = await tester.runAsync(() => content.obj('reading/books/sherlock-holmes/ch-12.json'));
    final text = str(jsonList(c!['blocks'])[120]['text']);
    final f = _para(text);
    expect(f, findsOneWidget);
    final r = tester.getRect(f);
    expect(r.top, inInclusiveRange(0, 915), reason: 'el párrafo 120 queda en la pantalla');
  });
}
