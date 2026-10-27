import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Grabaciones para compararse con el modelo. Quedan en la carpeta temporal del teléfono y no se
/// envían a ningún lado.
class Voice {
  // se crean al usarlos por primera vez: quien no graba no inicializa los plugins de audio
  AudioRecorder? _r;
  AudioPlayer? _p;
  AudioRecorder get _rec => _r ??= AudioRecorder();
  AudioPlayer get _player => _p ??= AudioPlayer();
  int _n = 0;

  /// Pide el permiso del micrófono la primera vez.
  Future<bool> allowed() async {
    try {
      return await _rec.hasPermission();
    } catch (_) {
      return false;
    }
  }

  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/trilex-${DateTime.now().millisecondsSinceEpoch}-${_n++}.wav';
    // WAV porque lo graban y reproducen todas las plataformas (Android, iOS y Linux)
    await _rec.start(const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1), path: path);
  }

  Future<String?> stop() => _rec.stop();

  Future<void> cancel() async {
    final r = _r;
    if (r != null && await r.isRecording()) await r.cancel();
  }

  Future<void> play(String path) async {
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  Future<void> stopPlaying() async => _p?.stop();
}
