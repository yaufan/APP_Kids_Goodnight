import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/version.dart';
import '../../core/content.dart';
import '../../core/game.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';

/// Parent mode (after the gate; docs/design.md 「家長模式」): the age, the
/// evening's minutes, tonight's parts and their order, the lullaby, reading
/// the story, the screen's darkness and the sound, the one-hour lock, the
/// last seven days and the full version.
class ParentScreen extends ConsumerStatefulWidget {
  const ParentScreen({super.key});

  @override
  ConsumerState<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends ConsumerState<ParentScreen> {
  late final Sounds _sounds = ref.read(soundsProvider);

  @override
  void initState() {
    super.initState();
    _sounds.hold(this, null);
  }

  @override
  void dispose() {
    _sounds.release(this);
    super.dispose();
  }

  void _close() => context.canPop() ? context.pop() : context.go('/');

  /// Tonight from the start (and the hour's lock lifted).
  void _restart() {
    ref.read(gameProvider.notifier).change((g) => g.copyWith(unlock: true));
    ref.read(eveningProvider.notifier).restart();
    context.go(ref.read(gameProvider).settings.lullabyOnly ? '/lullaby' : '/');
  }

  @override
  Widget build(BuildContext context) {
    final g = ref.watch(gameProvider);
    final s = g.settings;
    final game = ref.read(gameProvider.notifier);
    final now = ref.read(clockProvider)();
    const note = TextStyle(fontSize: 14, height: 1.5, color: Night.parentSoft);

    Widget section(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 15, color: Night.parentSoft, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...children,
              ]),
            ),
          ),
        );

    Widget toggle(String label, bool value, void Function(bool)? set, {Key? key, String? sub}) => SwitchListTile(
          key: key,
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: const TextStyle(fontSize: 17)),
          subtitle: sub == null ? null : Text(sub, style: const TextStyle(fontSize: 13, color: Night.parentSoft)),
          value: value,
          onChanged: set,
        );

    Widget chips<T>(List<T> values, T selected, String Function(T) label, void Function(T) pick, String keyOf, {bool Function(T)? enabled}) =>
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final v in values)
            ChoiceChip(
              key: ValueKey('$keyOf-${v is Enum ? v.name : v}'),
              label: Text(label(v), style: const TextStyle(fontSize: 16)),
              selected: v == selected,
              onSelected: (enabled?.call(v) ?? true) ? (_) => pick(v) : null,
              selectedColor: const Color(0xFFCDE7E4),
              showCheckmark: false,
            ),
        ]);

    final week = g.week(now);
    final locked = g.locked(now);
    return Theme(
      data: NightTheme.parent(),
      child: Scaffold(
        backgroundColor: Night.parentBg,
        appBar: AppBar(
          backgroundColor: Night.parentBg,
          title: const Text(Strings.parentTitle),
          leading: IconButton(key: const ValueKey('parent-close'), icon: const Icon(Icons.close_rounded), tooltip: Strings.back, onPressed: _close),
        ),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
          section(Strings.tonight, [
            if (locked) ...[
              Text(Strings.lockedLine(Game.lockLength.inMinutes - now.difference(g.goodnightAt!).inMinutes), style: const TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 8),
            ],
            FilledButton.tonal(key: const ValueKey('restart'), onPressed: _restart, child: Text(locked ? Strings.unlock : Strings.restart)),
          ]),
          section(Strings.age, [
            chips(Level.values, s.level, (l) => l.zh, (v) => game.settings((x) => x.copyWith(level: v)), 'level'),
            const SizedBox(height: 8),
            const Text(Strings.ageNote, style: note),
          ]),
          section(Strings.evening, [
            chips(Settings.minuteChoices, s.minutes, Strings.minutes, (v) => game.settings((x) => x.copyWith(minutes: v)), 'minutes'),
            const SizedBox(height: 8),
            const Text(Strings.eveningNote, style: note),
          ]),
          section(Strings.parts, [
            for (final (i, seg) in s.order.indexed)
              Row(children: [
                SizedBox(
                  width: 40,
                  child: i == 0
                      ? null
                      : IconButton(
                          key: ValueKey('up-${seg.name}'),
                          tooltip: Strings.moveUp,
                          icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                          onPressed: () => game.settings((x) => x.moveUp(seg)),
                        ),
                ),
                Expanded(
                  child: toggle(
                    seg.zh,
                    seg == Segment.lights || (!s.off.contains(seg) && (seg != Segment.checklist || s.full)),
                    seg == Segment.lights || (seg == Segment.checklist && !s.full) ? null : (on) => game.settings((x) => x.copyWith(off: on ? ({...x.off}..remove(seg)) : {...x.off, seg})),
                    key: ValueKey('part-${seg.name}'),
                    sub: seg == Segment.checklist && !s.full ? Strings.checklistFull : seg.note,
                  ),
                ),
              ]),
            Row(children: [
              const SizedBox(width: 40),
              Expanded(
                child: toggle(Segment.lullaby.zh, !s.off.contains(Segment.lullaby), (on) => game.settings((x) => x.copyWith(off: on ? ({...x.off}..remove(Segment.lullaby)) : {...x.off, Segment.lullaby})),
                    key: const ValueKey('part-lullaby'), sub: Segment.lullaby.note),
              ),
            ]),
            const Text(Strings.partsNote, style: note),
          ]),
          section(Strings.lullabySection, [
            chips(Lullaby.values, s.lullaby, (l) => l.isFree || s.full ? l.zh : '${l.zh}（${Strings.fullOnly}）', (v) => game.settings((x) => x.copyWith(lullaby: v)), 'lullaby',
                enabled: (l) => s.full || l.isFree),
            const SizedBox(height: 12),
            const Text(Strings.lullabyLength, style: TextStyle(fontSize: 15)),
            const SizedBox(height: 6),
            chips(Settings.lullabyChoices, s.lullabyMinutes, Strings.minutes, (v) => game.settings((x) => x.copyWith(lullabyMinutes: v)), 'lullaby-minutes'),
            const SizedBox(height: 6),
            toggle(Strings.lullabyOnly, s.lullabyOnly, (v) => game.settings((x) => x.copyWith(lullabyOnly: v)), key: const ValueKey('lullaby-only'), sub: Strings.lullabyOnlyNote),
          ]),
          section(Strings.storySection, [
            toggle(Strings.readStory, s.readStory, (v) => game.settings((x) => x.copyWith(readStory: v)), key: const ValueKey('read-story'), sub: Strings.readStoryNote),
            toggle(Strings.slowVoice, s.slowVoice, (v) => game.settings((x) => x.copyWith(slowVoice: v)), key: const ValueKey('slow-voice')),
          ]),
          section(Strings.screenSound, [
            Text(Strings.dim, style: const TextStyle(fontSize: 17)),
            Slider(key: const ValueKey('dim'), value: s.dim, max: Settings.maxDim, divisions: 6, onChanged: (v) => game.settings((x) => x.copyWith(dim: v))),
            const Text(Strings.dimNote, style: note),
            const SizedBox(height: 10),
            Text(Strings.volume, style: const TextStyle(fontSize: 17)),
            Slider(key: const ValueKey('volume'), value: s.volume, min: 0.2, max: 1, divisions: 8, onChanged: (v) => game.settings((x) => x.copyWith(volume: v))),
            toggle(Strings.effects, s.sounds, (v) => game.settings((x) => x.copyWith(sounds: v)), key: const ValueKey('effects')),
            toggle(Strings.voice, s.voice, (v) => game.settings((x) => x.copyWith(voice: v)), key: const ValueKey('voice')),
          ]),
          section(Strings.week, [
            if (week.nights == 0)
              const Text(Strings.weekNone, style: note)
            else ...[
              Text(Strings.weekLine(week.nights, week.averageMinutes), style: const TextStyle(fontSize: 16)),
              if (week.mostSkipped != null) ...[
                const SizedBox(height: 4),
                Text(Strings.mostSkipped(week.mostSkipped!), style: const TextStyle(fontSize: 15, color: Night.accent, fontWeight: FontWeight.w700)),
              ],
            ],
          ]),
          section(Strings.fullVersion, [
            const Text(Strings.fullNote, style: note),
            toggle(Strings.fullSwitch, s.full, (v) => game.settings((x) => x.copyWith(full: v)), key: const ValueKey('full')),
          ]),
          section(Strings.about, [
            const Text(Strings.privacy, style: TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 6),
            Text(Strings.version(appVersion), style: note),
          ]),
        ]),
      ),
    );
  }
}
