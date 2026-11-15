import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/content.dart';
import '../../core/evening.dart';
import '../../core/providers.dart';
import '../../core/screen.dart';
import '../../core/sounds.dart';

/// 搖籃曲與白噪音 (docs/design.md): a sound and how long it plays; then only
/// a faint moon and 「還剩 18 分鐘」, and the whole screen slowly goes black
/// (the window's own brightness turned down too). The phone stays awake but
/// gives no light. The sound gets quieter over the last two minutes; when
/// the time is up the evening says good night and the app closes itself.
class LullabyView extends ConsumerStatefulWidget {
  const LullabyView({super.key, required this.onDone, this.startBlack = false});

  final VoidCallback onDone;

  /// Straight to the black screen (「只要搖籃曲」, or opened again within the hour).
  final bool startBlack;

  /// Untouched this long, the choices fade away…
  static const choicesFor = Duration(seconds: 20);

  /// …and from here the screen goes black over [blackening].
  static const blackFrom = Duration(seconds: 30);
  static const blackening = Duration(seconds: 30);

  @override
  ConsumerState<LullabyView> createState() => _LullabyViewState();
}

class _LullabyViewState extends ConsumerState<LullabyView> {
  late final Sounds _sounds = ref.read(soundsProvider);
  late final ScreenControl _screen = ref.read(screenProvider);
  late final int _night = nightNumber(_now());
  late Lullaby _sound = ref.read(gameProvider).settings.sound;
  late LullabyClock _clock = LullabyClock(_now(), ref.read(gameProvider).settings.lullabyMinutes);
  late DateTime _lastTouch = widget.startBlack ? _now().subtract(const Duration(seconds: 50)) : _now();
  Timer? _tick, _say;
  var _dimmed = false;
  var _ended = false;

  DateTime _now() => ref.read(clockProvider)();

  @override
  void initState() {
    super.initState();
    _screen.keepOn(true);
    _music();
    if (!widget.startBlack) {
      _say = Timer(const Duration(milliseconds: 900), () {
        if (mounted) speak(ref, Strings.lullabyStart);
      });
    }
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _say?.cancel();
    _sounds.release(this);
    if (_dimmed) _screen.dim(false);
    super.dispose();
  }

  void _music() => _sounds.hold(this, Music.of(_sound, _night), level: _clock.volume(_now()));

  bool get _onTop => ModalRoute.of(context)?.isCurrent ?? true;

  Duration get _idle => _now().difference(_lastTouch);

  double get _black {
    final s = (_idle - LullabyView.blackFrom).inMilliseconds / LullabyView.blackening.inMilliseconds;
    return s.clamp(0.0, 1.0);
  }

  void _update() {
    if (!mounted || _ended) return;
    final now = _now();
    if (_clock.done(now)) {
      if (!_onTop) return;
      _ended = true;
      _tick?.cancel();
      _sounds.hold(this, null);
      widget.onDone();
      return;
    }
    if (_onTop) _music();
    final black = _black >= 1;
    if (black != _dimmed) {
      _dimmed = black;
      _screen.dim(black);
    }
    setState(() {});
  }

  void _touch() {
    // On the dark screen a touch only brings back the moon for a moment.
    _lastTouch = _idle >= LullabyView.choicesFor ? _now().subtract(const Duration(seconds: 25)) : _now();
    if (_dimmed) {
      _dimmed = false;
      _screen.dim(false);
    }
    setState(() {});
  }

  void _pick(Lullaby l) {
    setState(() => _sound = l);
    _music();
  }

  void _length(int m) => setState(() => _clock = LullabyClock(_clock.started, m));

  @override
  Widget build(BuildContext context) {
    final full = ref.watch(gameProvider.select((g) => g.settings.full));
    final choices = _idle < LullabyView.choicesFor;
    final now = _now();
    return Listener(
      key: const ValueKey('lullaby'),
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _touch(),
      child: Stack(
        children: [
          const Positioned.fill(
            child: NightSky(top: Night.deep, bottom: Night.sky, stars: 0.5),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final moon = (box.maxWidth * 0.36).clamp(90.0, 200.0);
                return Column(
                  children: [
                    const ScreenTitle(Strings.lullabyTitle),
                    const SizedBox(height: 16),
                    AnimatedOpacity(
                      opacity: choices ? 1 : 0,
                      duration: const Duration(seconds: 2),
                      child: IgnorePointer(
                        ignoring: !choices,
                        child: Column(
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: [
                                for (final l in Lullaby.values)
                                  if (full || l.isFree) _SoundTile(sound: l, selected: l == _sound, onTap: () => _pick(l)),
                              ],
                            ),
                            const SizedBox(height: 22),
                            const Text(Strings.howLong, style: TextStyle(fontSize: 15, color: Night.soft)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              children: [
                                for (final m in const [10, 20, 30])
                                  SoftButton(key: ValueKey('minutes-$m'), label: Strings.minutes(m), height: 44, fontSize: 17, selected: _clock.minutes == m, onTap: () => _length(m)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Opacity(
                      opacity: 0.75,
                      child: SizedBox(
                        width: moon,
                        height: moon,
                        child: const Drift(amount: 3, seconds: 10, child: Art(ArtPath.moon)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(Strings.minutesLeft(_clock.minutesLeft(now)), style: TextStyle(fontSize: 19, color: Night.soft.withValues(alpha: 0.7))),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: choices ? 1 : 0,
                      duration: const Duration(seconds: 2),
                      child: const Column(
                        children: [
                          Text(
                            Strings.lullabyNote,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, height: 1.5, color: Night.text),
                          ),
                          SizedBox(height: 12),
                          Text(Strings.lullabyFoot, style: TextStyle(fontSize: 13, color: Night.faint)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                );
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                key: const ValueKey('black'),
                opacity: _black,
                duration: const Duration(milliseconds: 1000),
                child: const ColoredBox(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundTile extends ConsumerWidget {
  const _SoundTile({required this.sound, required this.selected, required this.onTap});

  final Lullaby sound;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Semantics(
    container: true,
    button: true,
    selected: selected,
    label: sound.zh,
    excludeSemantics: true,
    onTap: onTap,
    child: GestureDetector(
      key: ValueKey('sound-${sound.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(soundsProvider).play('tap');
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        width: 96,
        height: 84,
        decoration: BoxDecoration(
          color: selected ? Night.cardEdge : Night.card.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? Night.warm.withValues(alpha: 0.7) : Night.cardEdge, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Tinted(ArtPath.lullaby(sound), color: selected ? Night.warm : Night.soft, size: 34),
            const SizedBox(height: 6),
            Text(sound.zh, style: TextStyle(fontSize: 15, color: selected ? Night.warm : Night.soft)),
          ],
        ),
      ),
    ),
  );
}

/// The good night after the last part (docs/design.md): on a black screen,
/// 「換你去睡了，晚安。」, a few soft notes, and the app closes itself (on
/// iOS, which does not allow that, the black screen stays).
class ClosingView extends ConsumerStatefulWidget {
  const ClosingView({super.key});

  static const stay = Duration(seconds: 8);

  @override
  ConsumerState<ClosingView> createState() => _ClosingViewState();
}

class _ClosingViewState extends ConsumerState<ClosingView> {
  late final Sounds _sounds = ref.read(soundsProvider);
  final _timers = <Timer>[];
  var _shown = false;

  @override
  void initState() {
    super.initState();
    _sounds.hold(this, null);
    _timers.add(
      Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() => _shown = true);
        _sounds.play('goodnight');
      }),
    );
    _timers.add(
      Timer(const Duration(milliseconds: 1800), () {
        if (mounted) speak(ref, Strings.yourTurnToSleep);
      }),
    );
    _timers.add(
      Timer(ClosingView.stay, () async {
        if (!mounted) return;
        final router = GoRouter.of(context);
        await ref.read(screenProvider).close();
        router.go('/ended');
      }),
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _sounds.release(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const ValueKey('closing'),
    color: Colors.black,
    child: Center(
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: const Duration(seconds: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Opacity(opacity: 0.5, child: SizedBox(width: 90, height: 90, child: Art(ArtPath.moon))),
            const SizedBox(height: 18),
            Text(Strings.yourTurnToSleep, style: TextStyle(fontSize: 28, color: Night.text.withValues(alpha: 0.75))),
          ],
        ),
      ),
    ),
  );
}

/// Only the black screen and the lullaby (「只要搖籃曲」, or opened again
/// within an hour of good night, so it is not 「再玩一次」).
class LullabyOnlyScreen extends ConsumerStatefulWidget {
  const LullabyOnlyScreen({super.key});

  @override
  ConsumerState<LullabyOnlyScreen> createState() => _LullabyOnlyScreenState();
}

class _LullabyOnlyScreenState extends ConsumerState<LullabyOnlyScreen> {
  var _ended = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final now = ref.read(clockProvider)();
      // 「只要搖籃曲」 is good night too: an hour of only this.
      if (!ref.read(gameProvider).locked(now)) ref.read(gameProvider.notifier).change((g) => g.copyWith(goodnightAt: now));
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: KidScale(
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1400),
              layoutBuilder: fillSwitcher,
              child: _ended ? const ClosingView() : LullabyView(key: const ValueKey('only'), startBlack: true, onDone: () => setState(() => _ended = true)),
            ),
          ),
          const Positioned.fill(child: DimLayer()),
          const ParentCorner(faint: true),
        ],
      ),
    ),
  );
}
