import 'package:flutter_test/flutter_test.dart';
import 'package:trilex/core/util.dart';

void main() {
  group('normAnswer', () {
    test('ignora mayúsculas, espacios, apóstrofos y puntuación final', () {
      expect(normAnswer('  It’s   OK!  '), 'its ok');
      expect(normAnswer("I'm fine."), normAnswer('im fine'));
    });

    test('respeta mayúsculas si se pide', () {
      expect(normAnswer('Hello.', caseSensitive: true), 'Hello');
      expect(normAnswer('Hello', caseSensitive: true) == normAnswer('hello', caseSensitive: true), isFalse);
    });
  });

  test('normWord deja solo letras, apóstrofo y guion', () {
    expect(normWord('Don’t!'), "don't");
    expect(normWord('Well-known,'), 'well-known');
  });

  test('fmtScore muestra como máximo un decimal', () {
    expect(fmtScore(7), '7');
    expect(fmtScore(7.5), '7.5');
    expect(fmtScore(7.46), '7.5');
    expect(fmtScore(6.96), '7');
  });

  test('sentence pega la puntuación a la palabra anterior', () {
    expect(sentence(['I', 'am', 'here', '.']), 'I am here.');
    expect(sentence(['Is', 'it', 'yours', '?']), 'Is it yours?');
  });

  test('joinLines une solo los campos de varias líneas', () {
    final out = joinLines({
      'md': ['a', 'b'],
      'x': {
        'text': ['c', 'd'],
      },
      'options': ['e', 'f'],
    });
    expect(out, {
      'md': 'a\nb',
      'x': {'text': 'c\nd'},
      'options': ['e', 'f'],
    });
  });

  test('dayKey usa el formato de la web', () {
    expect(dayKey(DateTime(2026, 3, 5)), '2026-03-05');
  });

  group('seededShuffle', () {
    const seed = "Who is Holmes's client in this story?";

    test('da el mismo orden que la web', () {
      expect(seededShuffle(['A', 'B', 'C', 'D'], seed), ['B', 'D', 'C', 'A']);
    });

    test('es estable y no pierde elementos', () {
      final a = ['one', 'two', 'three', 'four'];
      expect(seededShuffle(a, seed), seededShuffle(a, seed));
      expect(seededShuffle(a, seed).toSet(), a.toSet());
    });
  });
}
