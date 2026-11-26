import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/content.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';

/// 呼吸小月亮 (docs/design.md): hold the moon and it slowly grows (about four
/// seconds) — breathe in; let go and it slowly shrinks (about six) — breathe
/// out. Three times (five for 4～5 歲). The moon shows how once by itself
/// first; whether the child joins in or not, the evening moves on.
class BreathView extends ConsumerStatefulWidget {
  const BreathView({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<BreathView> createState() => _BreathViewState();
}

enum _Phase { demo, waiting, inhale, exhale, done }

class _BreathViewState extends ConsumerState<BreathView> with SingleTickerProviderStateMixin, HushOnLeave {
  late final Sounds _sounds = ref.read(soundsProvider);
  late final int _total = ref.read(gameProvider).settings.level.breaths;
  late final _moon = AnimationController(vsync: this);
  final _timers = <Timer>[];

  /// Waits for a last line to be said before going on.
  final _waits = <Later>[];
  var _phase = _Phase.demo;
  var _count = 0;
  DateTime? _pressed;
  var _demo = true;
  var _seq = 0;

  @override
  void initState() {
    super.initState();
    _sounds.hold(this, Music.wind, level: 0.4);
    _later(const Duration(milliseconds: 900), () => speak(ref, Strings.breathStart));
    _later(const Duration(milliseconds: 3200), () {
      if (_demo) _inhale();
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    for (final w in _waits) {
      w.cancel();
    }
    _moon.dispose();
    _sounds.release(this);
    super.dispose();
  }

  void _later(Duration d, VoidCallback f) => _timers.add(Timer(d, () {
        if (mounted) f();
      }));

  void _finish() {
    if (mounted) widget.onDone();
  }

  void _inhale() {
    _seq++;
    setState(() => _phase = _Phase.inhale);
    _sounds.play('breath_in');
    speak(ref, Strings.breatheIn);
    _moon.animateTo(1, duration: Breath.inhale * (1 - _moon.value), curve: Curves.easeInOut);
    if (_demo) _later(Breath.inhale, _exhale);
  }

  void _exhale() {
    final seq = ++_seq;
    setState(() => _phase = _Phase.exhale);
    _sounds.play('breath_out');
    speak(ref, Strings.breatheOut);
    _moon.animateTo(0, duration: Breath.exhale * math.max(_moon.value, 0.05), curve: Curves.easeInOut);
    if (_demo) {
      _later(Breath.exhale, () {
        if (!_demo) return;
        _demo = false;
        setState(() => _phase = _Phase.waiting);
        speak(ref, Strings.yourTurn);
      });
    } else {
      _later(Breath.exhale, () {
        if (seq == _seq && _phase == _Phase.exhale) setState(() => _phase = _Phase.waiting);
      });
    }
  }

  void _down() {
    if (_phase == _Phase.done) return;
    _demo = false;
    _pressed = ref.read(clockProvider)();
    _inhale();
  }

  void _up() {
    final at = _pressed;
    if (at == null || _phase == _Phase.done) return;
    _pressed = null;
    final held = ref.read(clockProvider)().difference(at);
    _exhale();
    if (held < Breath.minHold) return;
    setState(() => _count++);
    if (_count >= _total) {
      _later(Breath.exhale, () {
        setState(() => _phase = _Phase.done);
        _waits.add(Later(const Duration(milliseconds: 4500), _finish, after: speak(ref, Strings.breathAll)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = switch (_phase) {
      _Phase.inhale => Strings.breatheIn,
      _Phase.exhale => Strings.breatheOut,
      _Phase.done => Strings.breathAll,
      _ => _demo ? Strings.breathStart : Strings.yourTurn,
    };
    return NightSky(
      key: const ValueKey('breath'),
      stars: 0.7,
      child: SafeArea(
        child: LayoutBuilder(builder: (context, box) {
          final size = math.min(box.maxWidth * 0.9, box.maxHeight * 0.52);
          return Column(children: [
            const ScreenTitle(Strings.breathTitle),
            SizedBox(height: box.maxHeight * 0.05),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 700),
              child: Text(word, key: ValueKey(word), textAlign: TextAlign.center, style: const TextStyle(fontSize: 34, color: Night.warm)),
            ),
            const Spacer(),
            Semantics(
              container: true,
              button: true,
              label: Strings.breathHint,
              child: Listener(
                key: const ValueKey('moon'),
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _down(),
                onPointerUp: (_) => _up(),
                onPointerCancel: (_) => _up(),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: AnimatedBuilder(
                    animation: _moon,
                    builder: (_, child) => Transform.scale(scale: 0.62 + 0.38 * _moon.value, child: child),
                    child: const Art(ArtPath.moonFull),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < _total; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _count ? Night.warm : Colors.transparent,
                    border: Border.all(color: i < _count ? Night.warm : Night.soft, width: 1.5),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(Strings.breathHint, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Night.soft)),
            ),
            const SizedBox(height: 24),
          ]);
        }),
      ),
    );
  }
}
