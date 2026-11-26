import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// The phone's own speech, in Taiwanese Mandarin, slow and low
/// (docs/design.md 「語音」: about 0.7 of normal, a second between lines).
/// Parents can turn it off, or read the story themselves.
abstract interface class Voice {
  set slow(bool on);

  /// The parent's volume (0.2 to 1), the same as the sounds'.
  set volume(double v);

  /// Says one line.
  Future<void> say(String text);

  /// Reads [lines] one after another with a pause between them; completes
  /// when done (or stopped).
  Future<void> read(List<String> lines, {Duration pause = const Duration(seconds: 1)});

  Future<void> stop();
}

class SystemVoice implements Voice {
  SystemVoice() {
    // Nothing is said while the app is out of sight.
    _life = AppLifecycleListener(onHide: stop);
  }

  late final AppLifecycleListener _life;
  FlutterTts? _tts;
  Future<FlutterTts>? _setUp;
  var _turn = 0;
  var _slow = true;
  var _volume = 0.7;

  static const slowRate = 0.33, normalRate = 0.45;

  /// The voice is a little softer than the parent's volume for the sounds.
  static const _voiceLevel = 0.9;

  @override
  set slow(bool on) {
    _slow = on;
    _tts?.setSpeechRate(on ? slowRate : normalRate);
  }

  @override
  set volume(double v) {
    _volume = v;
    _tts?.setVolume(_voiceLevel * v);
  }

  /// The engine, set up once. Every line waits for the whole set-up, so a
  /// line asked for while the first one is still setting up is not cut off
  /// by the first one's late stop() (or said in the wrong language): the
  /// newer line is the one said.
  Future<FlutterTts> _engine() => _setUp ??= () async {
        final tts = _tts = FlutterTts();
        await tts.awaitSpeakCompletion(true);
        await tts.setLanguage('zh-TW');
        await tts.setSpeechRate(_slow ? slowRate : normalRate);
        await tts.setPitch(0.95);
        await tts.setVolume(_voiceLevel * _volume);
        return tts;
      }();

  @override
  Future<void> say(String text) => read([text], pause: Duration.zero);

  @override
  Future<void> read(List<String> lines, {Duration pause = const Duration(seconds: 1)}) async {
    final turn = ++_turn;
    try {
      final tts = await _engine();
      // A newer line, or a stop, while this one waited.
      if (turn != _turn) return;
      await tts.stop();
      for (final l in lines) {
        if (turn != _turn) return;
        if (l.trim().isNotEmpty) await tts.speak(l);
        if (turn != _turn) return;
        if (pause > Duration.zero) await Future<void>.delayed(pause);
      }
    } catch (_) {
      // No speech engine (tests, or a phone without one): the words on
      // screen and the pictures are enough.
    }
  }

  @override
  Future<void> stop() async {
    _turn++;
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  void dispose() => _life.dispose();
}

class SilentVoice implements Voice {
  const SilentVoice();

  @override
  set slow(bool on) {}

  @override
  set volume(double v) {}

  @override
  Future<void> say(String text) async {}

  @override
  Future<void> read(List<String> lines, {Duration pause = const Duration(seconds: 1)}) async {}

  @override
  Future<void> stop() async {}
}

/// Remembers what was said, the volume, and how often it was stopped (tests).
class RecordingVoice implements Voice {
  final said = <String>[];
  var stops = 0;
  double? level;

  @override
  set slow(bool on) {}

  @override
  set volume(double v) => level = v;

  @override
  Future<void> say(String text) async => said.add(text);

  @override
  Future<void> read(List<String> lines, {Duration pause = const Duration(seconds: 1)}) async => said.addAll(lines);

  @override
  Future<void> stop() async => stops++;
}
