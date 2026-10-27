import 'package:flutter_test/flutter_test.dart';
import 'package:trilex/course/dicto_screen.dart';
import 'package:trilex/reading/activities.dart';
import 'package:trilex/reading/reading.dart';
import 'package:trilex/words/srs.dart';

void main() {
  test('sentencesOf no corta en abreviaturas como p.m.', () {
    expect(sentencesOf('We walked from 10 p.m. until 2 a.m. with torches. Nobody spoke.'),
        ['We walked from 10 p.m. until 2 a.m. with torches.', 'Nobody spoke.']);
  });

  test('dictogloss: contracciones y forma completa valen lo mismo', () {
    final orig = dgWords("I'm a student and I didn't go out.");
    final ok = compareWords(orig, dgWords('I am a student and I did not go out'));
    expect(ok.every((x) => x), isTrue);
    final miss = compareWords(orig, dgWords('I am a student and I go out'));
    expect(miss[miss.length - 3], isFalse); // «didn't»
  });

  test('tarjetas aceptan variantes razonables del lema', () {
    expect(cardMatches('how do you spell...?', 'How do you spell'), isTrue);
    expect(cardMatches('fall out (with)', 'fall out'), isTrue);
    expect(cardMatches('fall out (with)', 'fall out with'), isTrue);
    expect(cardMatches('a / an', 'an'), isTrue);
    expect(cardMatches('yes, I am', 'yes I am'), isTrue);
    expect(cardMatches('goodbye', 'good bye'), isFalse);
  });

  test('frases: cada palabra se prueba en su forma base', () {
    expect(Reading.phraseForms('got up'), contains('get up'));
    expect(Reading.phraseForms('having breakfast'), contains('have breakfast'));
  });

  test('repaso: acierto sube una caja, error vuelve a la 1', () {
    final w = <String, dynamic>{};
    grade(w, 0, true);
    expect(w['box'], 1);
    grade(w, 5, true);
    expect(w['box'], 6);
    grade(w, 6, true);
    expect(w['box'], 6);
    grade(w, 4, false);
    expect(w['box'], 1);
  });
}
