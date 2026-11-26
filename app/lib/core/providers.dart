import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content.dart';
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

/// Who wants the screen kept awake (the evening, the lullaby) while it is
/// on top: off as soon as nobody does (a parent screen over it, the end).
final awakeProvider = Provider<Awake>((ref) => Awake(ref.read(screenProvider)));

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
  /// The app was closed during tonight's evening and opened again within ten
  /// minutes: it goes on where it was, the time it was closed not counted.
  @override
  Evening build() {
    final g = ref.read(gameProvider), now = ref.read(clockProvider)();
    final fresh = Evening.start(g.settings, now);
    final t = g.tonight;
    if (t == null || !t.goesOn(now) || t.index >= fresh.plan.length || fresh.plan[t.index] == Segment.lullaby) return fresh;
    return Evening(plan: fresh.plan, started: now.subtract(t.used), index: t.index);
  }

  void set(Evening e) => state = e;

  /// A fresh evening (a parent's 重新開始): a new [Evening.run], so every
  /// part on screen starts again.
  void restart() => state = Evening.start(ref.read(gameProvider).settings, ref.read(clockProvider)(), run: state.run + 1);
}
