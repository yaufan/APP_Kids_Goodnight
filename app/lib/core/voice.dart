import 'package:flutter_tts/flutter_tts.dart';

/// The phone's own speech, in Taiwanese Mandarin, slow and low
/// (docs/design.md 「語音」: about 0.7 of normal, a second between lines).
/// Parents can turn it off, or read the story themselves.
abstract interface class Voice {
  set slow(bool on);

  /// Says one line.
  Future<void> say(String text);

  /// Reads [lines] one after another with a pause between them; completes
  /// when done (or stopped).
  Future<void> read(List<String> lines, {Duration pause = const Duration(seconds: 1)});

  Future<void> stop();
}

class SystemVoice implements Voice {
  FlutterTts? _tts;
  var _turn = 0;
  var _slow = true;

  static const slowRate = 0.33, normalRate = 0.45;

  @override
  set slow(bool on) {
    _slow = on;
    _tts?.setSpeechRate(on ? slowRate : normalRate);
  }

  Future<FlutterTts> _engine() async {
    final existing = _tts;
    if (existing != null) return existing;
    final tts = _tts = FlutterTts();
    await tts.awaitSpeakCompletion(true);
    await tts.setLanguage('zh-TW');
    await tts.setSpeechRate(_slow ? slowRate : normalRate);
    await tts.setPitch(0.95);
    await tts.setVolume(0.8);
    return tts;
  }

  @override
  Future<void> say(String text) => read([text], pause: Duration.zero);

  @override
  Future<void> read(List<String> lines, {Duration pause = const Duration(seconds: 1)}) async {
    final turn = ++_turn;
    try {
      final tts = await _engine();
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
}

class SilentVoice implements Voice {
  const SilentVoice();

  @override
  set slow(bool on) {}

  @override
  Future<void> say(String text) async {}

  @override
  Future<void> read(List<String> lines, {Duration pause = const Duration(seconds: 1)}) async {}

  @override
  Future<void> stop() async {}
}

/// Remembers what was said (tests).
class RecordingVoice implements Voice {
  final said = <String>[];

  @override
  set slow(bool on) {}

  @override
  Future<void> say(String text) async => said.add(text);

  @override
  Future<void> read(List<String> lines, {Duration pause = const Duration(seconds: 1)}) async => said.addAll(lines);

  @override
  Future<void> stop() async {}
}
