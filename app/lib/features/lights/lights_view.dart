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
import '../../core/street_layout.dart';

/// 關燈巡邏 (docs/design.md): the street at dusk; tap a lit window or lamp
/// and it slowly goes dark, its animal yawns and falls asleep. Each light
/// out makes the town a little darker and quieter. No order, no failing:
/// a window already dark just goes 「噗」.
class LightsView extends ConsumerStatefulWidget {
  const LightsView({super.key, required this.onDone});

  final VoidCallback onDone;

  static const fadeOut = Duration(milliseconds: 1800);

  @override
  ConsumerState<LightsView> createState() => _LightsViewState();
}

class _LightsViewState extends ConsumerState<LightsView> {
  late final Sounds _sounds = ref.read(soundsProvider);
  late final List<Light> _lit = ref.read(gameProvider).settings.level.lights;
  final _off = <Light>{};
  final _timers = <Timer>[];
  late final String _line = isDaytime(ref.read(clockProvider)()) ? Strings.notYet : Strings.lightsStart;
  var _ended = false;

  double get _dark => _lit.isEmpty ? 1 : _off.length / _lit.length;

  @override
  void initState() {
    super.initState();
    _music();
    _later(const Duration(milliseconds: 900), () => speak(ref, _line));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _sounds.release(this);
    super.dispose();
  }

  void _later(Duration d, VoidCallback f) => _timers.add(Timer(d, () {
        if (mounted) f();
      }));

  void _music() => _sounds.hold(this, Music.street(_dark), level: 1 - 0.35 * _dark);

  void _tap(Light l) {
    if (!_lit.contains(l) || _off.contains(l)) {
      _sounds.play('puff_soft');
      return;
    }
    setState(() => _off.add(l));
    _sounds.play('puff');
    final a = l.animal;
    if (a != null) _later(const Duration(milliseconds: 500), () => _sounds.play(a.yawn));
    _later(const Duration(milliseconds: 1300), () => speak(ref, l.goodnight));
    _music();
    if (_off.length == _lit.length && !_ended) {
      _ended = true;
      _later(const Duration(milliseconds: 4200), () => speak(ref, Strings.lightsAll));
      _later(const Duration(milliseconds: 9000), widget.onDone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = _dark;
    final left = _lit.length - _off.length;
    return Stack(key: const ValueKey('lights'), children: [
      Positioned.fill(
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: dark),
          duration: LightsView.fadeOut,
          builder: (_, d, _) => NightSky(
            top: Color.lerp(Night.duskTop, Night.deep, d)!,
            bottom: Color.lerp(Night.duskLow, Night.skyLow, d)!,
            stars: 0.3 + 0.7 * d,
          ),
        ),
      ),
      LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        final k = math.min(w / streetCore.width, h * 0.64 / streetCore.height);
        final sw = streetSize.width * k, sh = streetSize.height * k;
        Rect at(Rect r) => Rect.fromLTWH(r.left * k, r.top * k, r.width * k, r.height * k);
        final moon = math.min(w, h) * 0.26;
        return Stack(children: [
          Positioned(right: w * 0.08, top: h * 0.2, width: moon, height: moon, child: const Drift(amount: 3, seconds: 9, child: Art(ArtPath.moon))),
          Positioned(
            left: (w - sw) / 2,
            top: h - sh,
            width: sw,
            height: sh,
            child: Stack(clipBehavior: Clip.none, children: [
              const Positioned.fill(child: Art(ArtPath.street, fit: BoxFit.fill)),
              Positioned.fill(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: dark),
                    duration: LightsView.fadeOut,
                    builder: (_, d, _) => ColoredBox(color: Colors.black.withValues(alpha: 0.28 * d)),
                  ),
                ),
              ),
              for (final l in Light.values) ..._light(l, lightsPlace(l), at),
            ]),
          ),
        ]);
      }),
      SafeArea(
        child: Column(children: [
          const ScreenTitle(Strings.lightsTitle),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 900),
            child: _Bubble(key: ValueKey(left == 0), text: left == 0 ? Strings.lightsAll : _line),
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            opacity: left == 0 ? 0 : 0.8,
            duration: const Duration(milliseconds: 900),
            child: Text(_off.isEmpty ? Strings.lightsHint : Strings.lightsLeft(left), style: const TextStyle(fontSize: 17, color: Night.soft)),
          ),
        ]),
      ),
    ]);
  }

  List<Widget> _light(Light l, LightPlace p, Rect Function(Rect) at) {
    final on = _lit.contains(l) && !_off.contains(l);
    final art = at(p.art), tap = at(p.tap);
    final animal = p.animal == null ? null : at(p.animal!);
    final pane = p.pane == null ? null : at(p.pane!);
    final a = l.animal;
    return [
      Positioned.fromRect(
        rect: art,
        child: IgnorePointer(child: AnimatedOpacity(opacity: on ? 1 : 0, duration: LightsView.fadeOut, curve: Curves.easeInOut, child: Art(ArtPath.glow(l), fit: BoxFit.fill))),
      ),
      if (animal != null && a != null)
        Positioned.fromRect(rect: animal, child: IgnorePointer(child: ClipRect(child: WindowAnimal(animal: a, asleep: !on, phase: l.index / 7)))),
      if (pane != null) Positioned.fromRect(rect: pane, child: const IgnorePointer(child: Art(ArtPath.grille, fit: BoxFit.fill))),
      if (animal != null && !on)
        Positioned(
          left: animal.right - animal.width * 0.25,
          top: animal.top - animal.height * 0.45,
          child: IgnorePointer(child: _FadeIn(delay: const Duration(milliseconds: 1600), child: Zz(size: animal.width * 0.55))),
        ),
      Positioned.fromRect(
        rect: tap,
        child: Semantics(
          container: true,
          button: true,
          label: 'light-${l.name}',
          excludeSemantics: true,
          onTap: () => _tap(l),
          child: Listener(
            key: ValueKey('light-${l.name}'),
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => _tap(l),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ];
  }
}

/// Where a light is on the street (street_layout.dart).
LightPlace lightsPlace(Light l) => lightPlaces[l]!;

/// An animal in its window: awake it sways a little; told to sleep, it
/// yawns (grows a little), then its eyes close and its head drops.
class WindowAnimal extends StatefulWidget {
  const WindowAnimal({super.key, required this.animal, required this.asleep, this.phase = 0, this.tokens});

  final Animal animal;
  final bool asleep;
  final double phase;

  /// Colours when awake (asleep it is always the soft blue sleeper).
  final Map<String, Color>? tokens;

  @override
  State<WindowAnimal> createState() => _WindowAnimalState();
}

class _WindowAnimalState extends State<WindowAnimal> with SingleTickerProviderStateMixin {
  late final _yawn = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500), value: widget.asleep ? 1 : 0);

  @override
  void didUpdateWidget(WindowAnimal old) {
    super.didUpdateWidget(old);
    if (widget.asleep && !old.asleep) _yawn.forward(from: 0);
    if (!widget.asleep && old.asleep) _yawn.value = 0;
  }

  @override
  void dispose() {
    _yawn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _yawn,
        builder: (_, _) {
          final t = _yawn.value;
          final sleeping = widget.asleep && t >= 0.55;
          final grow = widget.asleep && t < 0.55 ? 1 + 0.1 * math.sin(math.pi * t / 0.55) : 1.0;
          final picture = Art(
            ArtPath.animal(widget.animal, asleep: sleeping),
            tokens: sleeping ? AnimalPaint.dark : (widget.tokens ?? AnimalPaint.lit),
            alignment: Alignment.bottomCenter,
          );
          final body = Transform.scale(scale: grow, alignment: Alignment.bottomCenter, child: picture);
          return widget.asleep ? body : Drift(turn: 0.04, seconds: 3, phase: widget.phase, child: body);
        },
      );
}

class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> {
  var _shown = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(widget.delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(opacity: _shown ? 1 : 0, duration: const Duration(milliseconds: 1200), child: widget.child);
}

/// A soft rounded line of words on the night.
class _Bubble extends StatelessWidget {
  const _Bubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
        decoration: BoxDecoration(
          color: Night.deep.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Night.cardEdge),
        ),
        child: Text(text.replaceAll('。', ''), textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, color: Night.text)),
      );
}
