import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/content.dart';
import '../../core/evening.dart';
import '../../core/providers.dart';
import '../../core/screen.dart';
import '../breath/breath_view.dart';
import '../checklist/checklist_view.dart';
import '../lights/lights_view.dart';
import '../lullaby/lullaby_view.dart';
import '../sheep/sheep_view.dart';
import '../story/story_view.dart';

/// The evening (docs/design.md 「玩法」): one part after another, slowly
/// fading from one to the next. Nothing waits forever: a part nobody
/// touches for a long while quietly gives way to the next, and when the
/// parent's minutes are up the lullaby comes, wherever the evening is.
/// The screen is kept awake (by the window, no permission) until the end.
class EveningScreen extends ConsumerStatefulWidget {
  const EveningScreen({super.key});

  static const fade = Duration(milliseconds: 1400);

  @override
  ConsumerState<EveningScreen> createState() => _EveningScreenState();
}

class _EveningScreenState extends ConsumerState<EveningScreen> {
  Timer? _tick;
  late DateTime _lastTouch = _now();
  late final ScreenControl _screen = ref.read(screenProvider);

  DateTime _now() => ref.read(clockProvider)();

  @override
  void initState() {
    super.initState();
    _screen.keepOn(true);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _check());
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  /// Parent mode or the gate is on top: the evening waits.
  bool get _onTop => ModalRoute.of(context)?.isCurrent ?? true;

  void _check() {
    if (!mounted || !_onTop) return;
    final now = _now();
    final e = ref.read(eveningProvider);
    final s = ref.read(gameProvider).settings;
    if (e.overTime(now, s)) {
      _set(e.timeUp());
      return;
    }
    final seg = e.current;
    if (seg == null) return;
    final idle = Evening.idleLimit(seg, s);
    if (idle != null && now.difference(_lastTouch) >= idle) _set(e.next(passedBy: true));
  }

  void _next() => _set(ref.read(eveningProvider).next());

  void _set(Evening e) {
    if (!mounted) return;
    final before = ref.read(eveningProvider);
    final now = _now();
    ref.read(eveningProvider.notifier).set(e);
    _lastTouch = now;
    if (!before.saidGoodnight && e.saidGoodnight) {
      ref.read(gameProvider.notifier).change((g) => g.sayGoodnight(now, used: now.difference(e.started), skipped: e.skipped));
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = ref.watch(eveningProvider);
    final seg = e.current;
    final Widget view = switch (seg) {
      Segment.checklist => ChecklistView(onDone: _next),
      Segment.lights => LightsView(onDone: _next),
      Segment.sheep => SheepView(onDone: _next),
      Segment.story => StoryView(onDone: _next),
      Segment.breath => BreathView(onDone: _next),
      Segment.lullaby => LullabyView(onDone: _next),
      null => const ClosingView(),
    };
    return Scaffold(
      backgroundColor: Night.deep,
      body: KidScale(
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _lastTouch = _now(),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: EveningScreen.fade,
                  layoutBuilder: fillSwitcher,
                  child: KeyedSubtree(key: ValueKey('segment-${e.index}-${seg?.name ?? 'end'}'), child: view),
                ),
              ),
              const Positioned.fill(child: DimLayer()),
              ParentCorner(faint: seg == Segment.lullaby || seg == null),
            ],
          ),
        ),
      ),
    );
  }
}
