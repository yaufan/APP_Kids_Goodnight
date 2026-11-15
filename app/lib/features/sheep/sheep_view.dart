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

/// 數羊 (docs/design.md): a tap, and one fluffy sheep slowly (three
/// seconds) hops the fence and lies down to sleep; its number comes up big
/// and soft, and is said slowly. No tap, no hop: it waits.
class SheepView extends ConsumerStatefulWidget {
  const SheepView({super.key, required this.onDone});

  final VoidCallback onDone;

  /// The meadow picture's size (assets/art/sheep/meadow.svg).
  static const meadow = Size(600, 260);

  @override
  ConsumerState<SheepView> createState() => _SheepViewState();
}

class _SheepViewState extends ConsumerState<SheepView> with SingleTickerProviderStateMixin {
  late final Sounds _sounds = ref.read(soundsProvider);
  late final int _total = ref.read(gameProvider).settings.level.sheep;
  late final _hop = AnimationController(vsync: this, duration: sheepJump)..addStatusListener(_landed);
  final _timers = <Timer>[];
  var _count = 0;
  var _jumping = false;

  static const _from = Offset(196, 180), _to = Offset(404, 184), _height = 92.0;

  @override
  void initState() {
    super.initState();
    _sounds.hold(this, Music.wind, level: 0.55);
    _later(const Duration(milliseconds: 900), () => speak(ref, Strings.sheepStart));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _hop.dispose();
    _sounds.release(this);
    super.dispose();
  }

  void _later(Duration d, VoidCallback f) => _timers.add(Timer(d, () {
        if (mounted) f();
      }));

  void _tap() {
    if (_jumping || _count >= _total) return;
    setState(() => _jumping = true);
    _hop.forward(from: 0);
  }

  void _landed(AnimationStatus s) {
    if (s != AnimationStatus.completed || !mounted) return;
    setState(() {
      _jumping = false;
      _count++;
    });
    _sounds.play('sheep_hop');
    speak(ref, zhNumber(_count));
    _later(const Duration(milliseconds: 1200), () => _sounds.play('baa'));
    if (_count == _total) {
      _later(const Duration(milliseconds: 2600), () => speak(ref, Strings.sheepAll));
      _later(const Duration(milliseconds: 7000), widget.onDone);
    }
  }

  /// Where the n-th sheep sleeps (meadow units, its middle).
  static Offset _bed(int i) => Offset(292 + (i % 4) * 34 + (i ~/ 4 % 2) * 16, 206 + (i ~/ 4) * 11);

  @override
  Widget build(BuildContext context) {
    return Listener(
      key: const ValueKey('sheep'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _tap(),
      child: Semantics(
        container: true,
        button: true,
        label: Strings.sheepHint,
        onTap: _tap,
        child: NightSky(
          child: LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth, h = box.maxHeight;
            // The meadow fills the width (its far edges may be cut off on a narrow phone).
            final k = math.min(w / 330, h * 0.46 / SheepView.meadow.height);
            final mw = SheepView.meadow.width * k, mh = SheepView.meadow.height * k;
            final ox = (w - mw) / 2, oy = h - mh;
            Rect sheepAt(Offset c, double scale) {
              final sw = 92 * scale * k, sh = 74 * scale * k;
              return Rect.fromCenter(center: Offset(ox + c.dx * k, oy + c.dy * k), width: sw, height: sh);
            }

            final moon = math.min(w, h) * 0.24;
            return Stack(children: [
              Positioned(right: w * 0.1, top: h * 0.08, width: moon, height: moon, child: const Drift(amount: 3, seconds: 9, child: Art(ArtPath.moon))),
              Positioned(left: ox, top: oy, width: mw, height: mh, child: const Art(ArtPath.meadow, fit: BoxFit.fill)),
              for (var i = 0; i < _count; i++) Positioned.fromRect(rect: sheepAt(_bed(i), 0.7), child: const Art(ArtPath.sheepSleep)),
              if (_count < _total)
                AnimatedBuilder(
                  animation: _hop,
                  builder: (_, _) {
                    final t = Curves.easeInOut.transform(_hop.value);
                    final c = Offset.lerp(_from, _to, t)! - Offset(0, 4 * _height * t * (1 - t));
                    return Positioned.fromRect(
                      rect: sheepAt(c, 1.2),
                      child: Transform.rotate(angle: _jumping ? -0.18 * math.cos(math.pi * t) : 0, child: const Art(ArtPath.sheep)),
                    );
                  },
                ),
              SafeArea(
                child: SizedBox(
                  width: w,
                  child: Column(children: [
                    const ScreenTitle(Strings.sheepTitle),
                    SizedBox(height: h * 0.06),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1200),
                      child: _count == 0
                          ? const SizedBox(height: 190, key: ValueKey(0))
                          : Column(key: ValueKey(_count), children: [
                              Text('$_count', style: const TextStyle(fontSize: 110, height: 1.05, color: Night.warm)),
                              Text(zhNumber(_count), style: const TextStyle(fontSize: 40, color: Night.warm)),
                              const SizedBox(height: 8),
                              Text(Strings.sheepCount(_count).replaceFirst('$_count', zhNumber(_count)), style: const TextStyle(fontSize: 17, color: Night.soft)),
                            ]),
                    ),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 900),
                      child: _count == _total
                          ? const Text(Strings.sheepAll, key: ValueKey('all'), style: TextStyle(fontSize: 22, color: Night.text))
                          : Text(Strings.sheepHint, key: const ValueKey('hint'), style: TextStyle(fontSize: 16, color: Night.text.withValues(alpha: 0.6))),
                    ),
                    SizedBox(height: mh + 8),
                  ]),
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}
