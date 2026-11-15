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

  /// When parent mode (or the gate) covered the evening.
  DateTime? _awaySince;

  /// The part on screen is doing something by itself (reading the story).
  var _busy = false;
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
    if (!mounted) return;
    final now = _now();
    if (!_onTop) {
      _awaySince ??= now;
      return;
    }
    var e = ref.read(eveningProvider);
    final away = _awaySince;
    if (away != null) {
      // Time spent in parent mode does not count: not as the child being
      // idle, not against the parent's minutes.
      _awaySince = null;
      final gone = now.difference(away);
      _lastTouch = _lastTouch.add(gone);
      e = e.shifted(gone);
      ref.read(eveningProvider.notifier).set(e);
    }
    final s = ref.read(gameProvider).settings;
    if (e.overTime(now, s)) {
      _set(e.timeUp());
      return;
    }
    final seg = e.current;
    if (seg == null) return;
    final idle = Evening.idleLimit(seg, s);
    if (idle != null && !_busy && now.difference(_lastTouch) >= idle) _set(e.next(passedBy: true));
  }

  /// The part [index] of evening [run] starts or stops doing something by
  /// itself; the wait for a touch starts again after it.
  void _working(int run, int index, bool busy) {
    final e = ref.read(eveningProvider);
    if (!mounted || e.run != run || e.index != index) return;
    _busy = busy;
    _lastTouch = _now();
  }

  void _next() => _set(ref.read(eveningProvider).next());

  void _set(Evening e) {
    if (!mounted) return;
    final before = ref.read(eveningProvider);
    final now = _now();
    ref.read(eveningProvider.notifier).set(e);
    _lastTouch = now;
    _busy = false;
    if (!before.saidGoodnight && e.saidGoodnight) {
      ref.read(gameProvider.notifier).change((g) => g.sayGoodnight(now, used: now.difference(e.started), skipped: e.skipped));
    }
  }

  @override
  Widget build(BuildContext context) {
    // A parent started the evening again: a fresh wait for the first part.
    ref.listen(eveningProvider.select((e) => e.run), (_, _) {
      _lastTouch = _now();
      _busy = false;
      _awaySince = null;
    });
    final e = ref.watch(eveningProvider);
    final seg = e.current;
    final Widget view = switch (seg) {
      Segment.checklist => ChecklistView(onDone: _next),
      Segment.lights => LightsView(onDone: _next),
      Segment.sheep => SheepView(onDone: _next),
      Segment.story => StoryView(onDone: _next, onBusy: (b) => _working(e.run, e.index, b)),
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
                  child: KeyedSubtree(key: ValueKey('segment-${e.run}-${e.index}-${seg?.name ?? 'end'}'), child: view),
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
