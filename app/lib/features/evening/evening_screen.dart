import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/content.dart';
import '../../core/evening.dart';
import '../../core/game.dart';
import '../../core/providers.dart';
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
/// The screen is kept awake (by the window, no permission) while the evening
/// is on top. Time with a parent screen over it or with the app in the
/// background does not count (and a parent screen closes by itself after
/// five idle minutes, so the evening always reaches its end); a clock moved
/// back gives no extra time; closed and opened again within ten minutes, it
/// goes on (Game.tonight).
class EveningScreen extends ConsumerStatefulWidget {
  const EveningScreen({super.key});

  static const fade = Duration(milliseconds: 1400);

  /// Tonight is saved this often (in seconds).
  static const saveEvery = 30;

  @override
  ConsumerState<EveningScreen> createState() => _EveningScreenState();
}

class _EveningScreenState extends ConsumerState<EveningScreen> {
  Timer? _tick;
  AppLifecycleListener? _life;
  late DateTime _lastTouch = _now();

  /// When the evening stopped counting: parent mode (or the gate) over it,
  /// or the app in the background.
  DateTime? _awaySince;
  var _hidden = false;

  /// The phone's clock at the last check (to notice it moved back).
  late DateTime _seen = _now();
  var _checks = 0;

  /// The part on screen is doing something by itself (reading the story).
  var _busy = false;

  DateTime _now() => ref.read(clockProvider)();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _check());
    _life = AppLifecycleListener(
      onHide: () {
        _hidden = true;
        _awaySince ??= _now();
        _remember();
      },
      onShow: () {
        _hidden = false;
        _check();
      },
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    _life?.dispose();
    super.dispose();
  }

  /// Parent mode or the gate is on top: the evening waits.
  bool get _onTop => ModalRoute.of(context)?.isCurrent ?? true;

  /// Saves how far tonight has gone (before the lullaby), so the app opened
  /// again soon goes on with it.
  void _remember() {
    if (!mounted) return;
    final e = ref.read(eveningProvider);
    if (e.saidGoodnight) return;
    final now = _now();
    var used = (_awaySince ?? now).difference(e.started);
    if (used.isNegative) used = Duration.zero;
    ref.read(gameProvider.notifier).change((g) => g.copyWith(tonight: Tonight(used: used, index: e.index, seen: now)));
  }

  void _check() {
    if (!mounted) return;
    final now = _now();
    var e = ref.read(eveningProvider);
    if (now.isBefore(_seen)) {
      // The phone's clock moved back: the evening moves back with it.
      final d = now.difference(_seen);
      e = e.shifted(d);
      ref.read(eveningProvider.notifier).set(e);
      _lastTouch = _lastTouch.add(d);
      if (_awaySince != null) _awaySince = _awaySince!.add(d);
    }
    _seen = now;
    if (_hidden || !_onTop) {
      _awaySince ??= now;
      return;
    }
    final s = ref.read(gameProvider).settings;
    final away = _awaySince;
    if (away != null) {
      // Time spent in parent mode or in the background does not count:
      // not as the child being idle, not against the parent's minutes.
      _awaySince = null;
      final gone = now.difference(away);
      if (!gone.isNegative) {
        _lastTouch = _lastTouch.add(gone);
        e = e.shifted(gone);
        ref.read(eveningProvider.notifier).set(e);
      }
      // Tonight's parts changed in parent mode: they count from now.
      final plan = eveningPlan(s);
      if (!e.saidGoodnight && e.differs(plan)) {
        _set(e.replanned(plan));
        return;
      }
    }
    if (++_checks % EveningScreen.saveEvery == 0) _remember();
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
    } else if (before.index != e.index) {
      _remember();
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
    // The phone's back key does nothing in the middle of the evening.
    return AwakeOnTop(child: BackTo(child: Scaffold(
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
    )));
  }
}
