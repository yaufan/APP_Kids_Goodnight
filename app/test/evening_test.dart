import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodnight_town/core/content.dart';
import 'package:goodnight_town/core/game.dart';
import 'package:goodnight_town/core/providers.dart';
import 'package:goodnight_town/core/sounds.dart';
import 'package:goodnight_town/core/story.dart';
import 'package:goodnight_town/features/parent/parent_gate.dart';

import 'helpers.dart';

/// The evening's rules as they happen on screen (docs/design.md).
void main() {
  testWidgets('nobody taps the checklist: after a minute it moves on by itself', (tester) async {
    final app = await TestApp.start(tester);
    expect(app.evening.current, Segment.checklist);
    await app.wait(58);
    expect(app.evening.current, Segment.checklist);
    await app.wait(3);
    expect(app.evening.current, Segment.lights);
    expect(app.evening.skipped, [Segment.checklist]);
    await app.end();
  });

  testWidgets('the parent\'s minutes are up: the lullaby comes, wherever the evening is', (tester) async {
    final app = await TestApp.start(tester, game: const Game(settings: Settings(minutes: 5)));
    await app.tapKey('check-teeth');
    app.now = app.now.add(const Duration(minutes: 5));
    await app.wait(3);
    expect(app.evening.current, Segment.lullaby);
    expect(app.game.locked(app.now), isTrue);
    expect(app.game.history.single.skipped, [Segment.checklist, Segment.lights, Segment.sheep, Segment.story, Segment.breath]);
    expect(app.game.week(app.now).mostSkipped, isNotNull);
    await app.end();
  });

  testWidgets('the free version: no checklist, four sounds, the six fixed stories', (tester) async {
    final app = await TestApp.start(tester, game: const Game(settings: Settings(full: false, lullaby: Lullaby.heartbeat)));
    expect(app.evening.plan.first, Segment.lights);
    expect(Story.fixed, contains(app.game.storyFor(app.now)));
    app.container.read(eveningProvider.notifier).set(app.evening.timeUp());
    await app.wait(2);
    expect(app.evening.current, Segment.lullaby);
    for (final l in Lullaby.values) {
      expect(find.byKey(ValueKey('sound-${l.name}')), l.isFree ? findsOneWidget : findsNothing, reason: l.name);
    }
    expect(app.sounds.music, isIn([Music.musicBox1, Music.musicBox2, Music.musicBox3]), reason: 'the heartbeat is in the full version');
    await app.end();
  });

  testWidgets('a parent reads the story: the app does not read, the words are a prompt', (tester) async {
    final app = await TestApp.start(tester, game: Game(settings: const Settings(readStory: false).copyWith(off: {Segment.checklist}, order: [Segment.story, Segment.lights, Segment.sheep, Segment.breath, Segment.checklist])));
    expect(app.evening.current, Segment.story);
    await app.wait(8);
    final page = app.game.storyFor(app.now).pages(Level.small).first;
    for (final l in page.lines) {
      expect(find.text(l), findsOneWidget);
      expect(app.voice.said, isNot(contains(l)));
    }
    expect(find.text('請爸爸媽媽念給你聽'), findsOneWidget);
    expect(find.bySemanticsLabel('念給我聽'), findsNothing);
    await app.tapLabel('下一頁', ms: 1500);
    await app.tapLabel('晚安', ms: 3500);
    expect(app.evening.current, Segment.lights);
    await app.end();
  });

  testWidgets('daytime: the town is still at dusk, and the app says it is not bedtime yet', (tester) async {
    final app = await TestApp.start(tester, at: DateTime(2026, 11, 15, 10), game: Game(settings: const Settings().copyWith(off: {Segment.checklist})));
    await app.wait(2);
    expect(app.evening.current, Segment.lights);
    expect(app.voice.said, contains('現在還不是睡覺時間喔。'));
    await app.end();
  });

  testWidgets('「只要搖籃曲」: straight to the black screen and the sound; good night is said', (tester) async {
    final app = await TestApp.start(tester, game: const Game(settings: Settings(lullabyOnly: true, lullaby: Lullaby.waves, lullabyMinutes: 10)));
    expect(app.location, '/lullaby');
    await app.wait(2);
    expect(app.sounds.music, Music.waves);
    expect(app.game.locked(app.now), isTrue);
    await app.wait(12);
    expect(app.screen.dimmed, isTrue);
    // A touch brings back the moon for a moment.
    await app.tapKey('lullaby', ms: 400);
    expect(app.screen.dimmed, isFalse);
    expect(find.text('還剩 10 分鐘'), findsOneWidget);
    app.now = app.now.add(const Duration(minutes: 10));
    await app.wait(10);
    expect(app.screen.closed, 1);
    expect(app.location, '/ended');
    await app.end();
  });

  testWidgets('parent mode: turn parts off and move them, the lullaby\'s sound and length, the darkness', (tester) async {
    final app = await TestApp.start(tester);
    await app.tapKey('parent-corner', ms: 800);
    await app.answerGate();
    expect(app.location, '/parent');
    await tester.scrollUntilVisible(find.byKey(const ValueKey('part-lullaby')), 200, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 200));
    await app.settle();
    await tester.tap(find.byKey(const ValueKey('up-breath')));
    await app.settle();
    expect(app.game.settings.order.indexOf(Segment.breath), Segment.movable.indexOf(Segment.breath) - 1);
    await app.tapKey('part-sheep');
    expect(app.game.settings.off, contains(Segment.sheep));
    await app.tapKey('part-lights');
    expect(app.game.settings.off, isNot(contains(Segment.lights)), reason: 'the lights are always there');
    await tester.scrollUntilVisible(find.byKey(const ValueKey('lullaby-minutes-30')), 200, scrollable: find.byType(Scrollable).first);
    await app.tapKey('lullaby-rain');
    await app.tapKey('lullaby-minutes-30');
    expect(app.game.settings.lullaby, Lullaby.rain);
    expect(app.game.settings.lullabyMinutes, 30);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('dim')), 200, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byKey(const ValueKey('dim')), const Offset(200, 0));
    await app.settle();
    expect(app.game.settings.dim, greaterThan(0));
    await tester.scrollUntilVisible(find.byKey(const ValueKey('restart')), -200, scrollable: find.byType(Scrollable).first);
    await app.tapKey('restart', ms: 800);
    expect(app.location, '/');
    expect(app.evening.plan, isNot(contains(Segment.sheep)));
    expect(app.evening.plan.indexOf(Segment.breath), lessThan(app.evening.plan.indexOf(Segment.story)));
    expect(ParentPass.take(), isFalse);
    await app.end();
  });
}
