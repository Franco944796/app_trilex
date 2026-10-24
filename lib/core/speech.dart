import 'package:flutter_tts/flutter_tts.dart';

class Speech {
  final _tts = FlutterTts();
  void Function()? _onDone;

  Future<void> init() async {
    await _tts.setLanguage('en-GB');
    await _tts.awaitSpeakCompletion(false);
    _tts.setCompletionHandler(() {
      final f = _onDone;
      _onDone = null;
      if (f != null) f();
    });
  }

  /// Lee un texto. [rate] relativo como en la web: 0.9 normal, 0.6–0.7 lento, 1.05 rápido.
  Future<void> say(String text, {double rate = 0.9, void Function()? onDone}) async {
    await _tts.stop();
    _onDone = onDone;
    // la escala de flutter_tts es 0–1, con 0.5 como velocidad normal
    await _tts.setSpeechRate((rate * 0.5).clamp(0.2, 0.8).toDouble());
    await _tts.speak(text);
  }

  Future<void> stop() async {
    _onDone = null;
    await _tts.stop();
  }
}
