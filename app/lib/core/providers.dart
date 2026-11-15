import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'evening.dart';
import 'game.dart';
import 'screen.dart';
import 'sounds.dart';
import 'store.dart';
import 'voice.dart';

/// What time it is (tests, screenshots and the demo set it).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final storeProvider = Provider<GameStore>((ref) => MemoryStore());
final savedGameProvider = Provider<Game>((ref) => const Game());
final soundsProvider = Provider<Sounds>((ref) => const SilentSounds());
final voiceProvider = Provider<Voice>((ref) => const SilentVoice());
final screenProvider = Provider<ScreenControl>((ref) => RecordingScreen());

/// The settings and the evenings; every change is saved straight away.
final gameProvider = NotifierProvider<GameNotifier, Game>(GameNotifier.new);

class GameNotifier extends Notifier<Game> {
  @override
  Game build() => ref.read(savedGameProvider);

  void change(Game Function(Game g) f) {
    final next = f(state);
    if (identical(next, state)) return;
    state = next;
    ref.read(storeProvider).write(next.toJson());
  }

  void settings(Settings Function(Settings s) f) => change((g) => g.copyWith(settings: f(g.settings)));
}

/// Tonight's evening, from opening the app (a parent can start it again).
final eveningProvider = NotifierProvider<EveningNotifier, Evening>(EveningNotifier.new);

class EveningNotifier extends Notifier<Evening> {
  @override
  Evening build() => Evening.start(ref.read(gameProvider).settings, ref.read(clockProvider)());

  void set(Evening e) => state = e;

  void restart() => state = Evening.start(ref.read(gameProvider).settings, ref.read(clockProvider)());
}
