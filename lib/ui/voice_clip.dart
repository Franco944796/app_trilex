import 'dart:async';

import 'package:flutter/material.dart';

import '../core/services.dart';
import 'theme.dart';

/// «Grabarme» / «Detener» y, al terminar, «Mi grabación» para escucharse.
class VoiceClip extends StatefulWidget {
  const VoiceClip({super.key, this.maxSeconds = 15});
  final int maxSeconds;
  @override
  State<VoiceClip> createState() => _VoiceClipState();
}

class _VoiceClipState extends State<VoiceClip> {
  bool recording = false, denied = false;
  String? path;
  Timer? _limit;

  @override
  void dispose() {
    _limit?.cancel();
    if (recording) voice.cancel();
    voice.stopPlaying();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (recording) return _stop();
    if (!await voice.allowed()) {
      if (mounted) setState(() => denied = true);
      return;
    }
    await speech.stop();
    await voice.start();
    _limit = Timer(Duration(seconds: widget.maxSeconds), _stop);
    if (mounted) setState(() => recording = true);
  }

  Future<void> _stop() async {
    _limit?.cancel();
    if (!recording) return;
    final p = await voice.stop();
    if (mounted) {
      setState(() {
        recording = false;
        path = p;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (denied) return Text(tr('shNoMic'), style: TextStyle(fontSize: 13, color: Tx.muted));
    return Wrap(spacing: 8, runSpacing: 8, children: [
      OutlinedButton(
        onPressed: _toggle,
        style: recording ? OutlinedButton.styleFrom(foregroundColor: Tx.bad) : null,
        child: Text(recording ? '■ ${tr('rtStop')}' : '🎙 ${tr('shRec')}'),
      ),
      if (path != null && !recording)
        OutlinedButton(onPressed: () => voice.play(path!), child: Text('▶ ${tr('myRec')}')),
    ]);
  }
}
