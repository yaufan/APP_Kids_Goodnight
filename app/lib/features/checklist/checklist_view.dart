import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/content.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';

/// 晚安清單 (docs/design.md): brush teeth, potty, water, a hug — done for
/// real, then a tap: the picture goes dark and gives a little yawn. All
/// four done, and it is time to put the town to bed. Nobody has to tap:
/// after a minute it moves on by itself (evening_screen.dart).
class ChecklistView extends ConsumerStatefulWidget {
  const ChecklistView({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<ChecklistView> createState() => _ChecklistViewState();
}

class _ChecklistViewState extends ConsumerState<ChecklistView> with HushOnLeave {
  late final Sounds _sounds = ref.read(soundsProvider);
  final _done = <Check>{};
  final _timers = <Timer>[];

  /// Waits for a last line to be said before going on.
  final _waits = <Later>[];

  @override
  void initState() {
    super.initState();
    _sounds.hold(this, Music.wind, level: 0.5);
    _later(const Duration(milliseconds: 900), () => speak(ref, Strings.checklistLine));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    for (final w in _waits) {
      w.cancel();
    }
    _sounds.release(this);
    super.dispose();
  }

  void _later(Duration d, VoidCallback f) => _timers.add(Timer(d, () {
        if (mounted) f();
      }));

  void _finish() {
    if (mounted) widget.onDone();
  }

  void _tap(Check c) {
    if (_done.contains(c)) return;
    setState(() => _done.add(c));
    _sounds.play('yawn_small');
    speak(ref, Strings.checkDone(c));
    if (_done.length == Check.values.length) {
      // On to the town once 「都做好了」 has been said.
      _later(const Duration(milliseconds: 1800), () => _waits.add(Later(const Duration(milliseconds: 4200), _finish, after: speak(ref, Strings.checklistAll))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return NightSky(
      key: const ValueKey('checklist'),
      stars: 0.6,
      child: SafeArea(
        child: LayoutBuilder(builder: (context, box) {
          final side = (box.maxWidth - 3 * 22).clamp(0.0, box.maxHeight * 0.66 - 22) / 2;
          return Column(children: [
            const ScreenTitle(Strings.checklistTitle),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(Strings.checklistLine, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, color: Night.text)),
            ),
            const Spacer(),
            Wrap(spacing: 22, runSpacing: 22, alignment: WrapAlignment.center, children: [
              for (final c in Check.values) SizedBox(width: side, height: side, child: _Card(check: c, done: _done.contains(c), onTap: () => _tap(c))),
            ]),
            const Spacer(),
            AnimatedOpacity(
              opacity: _done.length == Check.values.length ? 1 : 0,
              duration: const Duration(milliseconds: 900),
              child: const Text(Strings.checklistAll, style: TextStyle(fontSize: 19, color: Night.warm)),
            ),
            const SizedBox(height: 18),
            const Text(Strings.checklistNote, style: TextStyle(fontSize: 13, color: Night.faint)),
            const SizedBox(height: 18),
          ]);
        }),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.check, required this.done, required this.onTap});

  final Check check;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        label: check.zh,
        excludeSemantics: true,
        onTap: onTap,
        child: Listener(
          key: ValueKey('check-${check.name}'),
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => onTap(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: done ? null : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Night.warm, Night.warmDeep]),
              color: done ? Night.card : null,
              border: Border.all(color: done ? Night.cardEdge : Night.warm, width: 1.5),
              boxShadow: done ? const [] : [BoxShadow(color: Night.warmDeep.withValues(alpha: 0.35), blurRadius: 26)],
            ),
            child: Stack(children: [
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 0.5,
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: done ? Night.faint : Night.silhouette),
                    duration: const Duration(milliseconds: 1400),
                    builder: (_, c, _) => Tinted(ArtPath.check(check), color: c!),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.82),
                child: Text(check.zh, style: TextStyle(fontSize: 20, color: done ? Night.faint : Night.silhouette, fontWeight: FontWeight.w700)),
              ),
              if (done) const Positioned(right: 14, top: 12, child: Zz(size: 26)),
            ]),
          ),
        ),
      );
}
