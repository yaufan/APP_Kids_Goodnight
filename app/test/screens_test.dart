import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodnight_town/core/content.dart';
import 'package:goodnight_town/core/evening.dart';
import 'package:goodnight_town/core/game.dart';
import 'package:goodnight_town/core/providers.dart';
import 'package:goodnight_town/features/parent/parent_gate.dart';

import 'helpers.dart';

/// The things checked again after 0.1.0 (the code review): a parent screen
/// left open, the brightness, the background, the clock, closing and opening
/// again, the back key, the gate's lock, the voice behind parent mode,
/// tonight's parts changed in parent mode.
void main() {
  Future<void> hide(TestApp app) async {
    for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      app.tester.binding.handleAppLifecycleStateChanged(s);
    }
    await app.tester.pump();
  }

  Future<void> show(TestApp app) async {
    for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      app.tester.binding.handleAppLifecycleStateChanged(s);
    }
    await app.settle(800);
  }

  /// The parent's minutes run out: the lullaby (and good night is said).
  Future<void> toLullaby(TestApp app) async {
    app.now = app.now.add(Duration(minutes: app.game.settings.minutes));
    await app.wait(2);
    expect(app.evening.current, Segment.lullaby);
  }

  /// [m] minutes pass on the fake timers without the app's clock (the
  /// parent screens' five idle minutes).
  Future<void> idle(TestApp app, int m) async {
    await app.tester.pump(Duration(minutes: m));
    await app.settle(1200);
  }

  bool gateOpen() => find.byType(ParentGatePage).evaluate().isNotEmpty;

  group('a parent screen left open', () {
    testWidgets('the gate over the lullaby: the brightness comes back, and the lullaby still ends on time', (tester) async {
      final app = await TestApp.start(tester, game: const Game(settings: Settings(lullabyMinutes: 10)));
      await toLullaby(app);
      expect(app.screen.awake, isTrue);
      await app.wait(62);
      expect(app.screen.dimmed, isTrue, reason: 'the lullaby went black');
      await app.tapKey('parent-corner', ms: 800);
      expect(gateOpen(), isTrue);
      expect(app.screen.dimmed, isFalse, reason: 'the gate is never dark');
      expect(app.screen.awake, isTrue, reason: 'the gate closes by itself within five minutes; the lullaby goes on');
      await app.wait(40);
      expect(app.screen.dimmed, isFalse);
      app.now = app.now.add(const Duration(minutes: 10));
      await app.wait(3);
      expect(gateOpen(), isFalse, reason: 'the lullaby is over: the gate goes');
      await app.wait(12);
      expect(app.screen.closed, 1);
      expect(app.screen.awake, isFalse);
      expect(app.location, '/ended');
      await app.end();
    });

    testWidgets('parent mode over the lullaby: the lullaby still ends on time and the app closes', (tester) async {
      final app = await TestApp.start(tester, game: const Game(settings: Settings(lullabyMinutes: 10)));
      await toLullaby(app);
      await app.tapKey('parent-corner', ms: 800);
      await app.answerGate();
      expect(app.location, '/parent');
      app.now = app.now.add(const Duration(minutes: 10));
      await app.wait(15);
      expect(app.screen.closed, 1);
      expect(app.screen.awake, isFalse);
      expect(app.location, '/ended');
      await app.end();
    });

    testWidgets('the gate and parent mode close by themselves after five minutes without a touch', (tester) async {
      final app = await TestApp.start(tester);
      await app.tapKey('parent-corner', ms: 800);
      expect(gateOpen(), isTrue);
      await idle(app, 4);
      await app.tapKey('gate-key-0', ms: 200);
      await idle(app, 4);
      expect(gateOpen(), isTrue, reason: 'a touch starts the five minutes again');
      await idle(app, 1);
      expect(gateOpen(), isFalse);
      expect(app.screen.awake, isTrue, reason: 'the evening is on top again');
      await app.tapKey('parent-corner', ms: 800);
      await app.answerGate();
      expect(app.location, '/parent');
      await idle(app, 5);
      expect(app.location, '/');
      app.go('/parent');
      await app.settle();
      expect(app.location, '/', reason: 'the pass is used up');
      await app.end();
    });

    testWidgets('the gate and parent mode close when the app goes to the background', (tester) async {
      final app = await TestApp.start(tester);
      await app.tapKey('parent-corner', ms: 800);
      await hide(app);
      await show(app);
      expect(gateOpen(), isFalse);
      await app.tapKey('parent-corner', ms: 800);
      await app.answerGate();
      expect(app.location, '/parent');
      await hide(app);
      await show(app);
      expect(app.location, '/');
      app.go('/parent');
      await app.settle();
      expect(app.location, '/', reason: 'a child opening the app meets the gate again');
      await app.end();
    });

    testWidgets('opened again within the hour: the gate over the black screen is not dark', (tester) async {
      final now = DateTime(2026, 11, 15, 20, 30);
      final app = await TestApp.start(tester, game: Game(goodnightAt: now.subtract(const Duration(minutes: 20))));
      expect(app.location, '/lullaby');
      await app.wait(12);
      expect(app.screen.dimmed, isTrue);
      await app.tapKey('parent-corner', ms: 800);
      expect(app.screen.dimmed, isFalse);
      await app.wait(30);
      expect(app.screen.dimmed, isFalse);
      await app.end();
    });
  });

  group('the background', () {
    testWidgets('a few minutes away: nothing is passed by and the minutes do not run', (tester) async {
      final app = await TestApp.start(tester, game: const Game(settings: Settings(minutes: 5)));
      await app.wait(40);
      await hide(app);
      app.now = app.now.add(const Duration(minutes: 9));
      await tester.pump(const Duration(seconds: 5));
      await show(app);
      await app.wait(3);
      expect(app.evening.current, Segment.checklist, reason: 'the checklist\'s minute does not count the time away');
      expect(app.evening.skipped, isEmpty);
      expect(app.game.locked(app.now), isFalse, reason: 'no lullaby, no hour\'s lock');
      await app.end();
    });

    testWidgets('ten minutes or more away: tonight starts afresh (or only the lullaby within the hour)', (tester) async {
      final app = await TestApp.start(tester);
      await app.tapKey('check-teeth');
      await app.wait(5);
      await hide(app);
      app.now = app.now.add(const Duration(minutes: 12));
      await show(app);
      expect(app.evening.run, 1);
      expect(app.evening.index, 0);
      await toLullaby(app);
      await hide(app);
      app.now = app.now.add(const Duration(minutes: 15));
      await show(app);
      await app.wait(2);
      expect(app.location, '/lullaby', reason: 'within the hour after good night');
      await app.end();
    });

    testWidgets('the lullaby waits while the app is away', (tester) async {
      final app = await TestApp.start(tester, game: const Game(settings: Settings(lullabyMinutes: 10)));
      await toLullaby(app);
      await app.wait(60);
      await hide(app);
      app.now = app.now.add(const Duration(minutes: 8));
      await show(app);
      await app.tapKey('lullaby');
      expect(find.text('還剩 9 分鐘'), findsOneWidget);
      expect(app.screen.closed, 0);
      await app.end();
    });
  });

  group('the clock and closing the app', () {
    testWidgets('a clock moved back gives no extra time', (tester) async {
      final app = await TestApp.start(tester, game: const Game(settings: Settings(minutes: 5)));
      await app.tapKey('check-teeth');
      await app.wait(10);
      app.now = app.now.subtract(const Duration(hours: 1));
      await app.wait(3);
      app.now = app.now.add(const Duration(minutes: 5));
      await app.wait(3);
      expect(app.evening.current, Segment.lullaby);
      await app.end();
    });

    testWidgets('closed and opened again within ten minutes, tonight goes on where it was', (tester) async {
      final now = DateTime(2026, 11, 15, 20, 30);
      final app = await TestApp.start(tester, at: now, game: Game(settings: const Settings(minutes: 5), tonight: Tonight(used: const Duration(minutes: 4, seconds: 50), index: 1, seen: now.subtract(const Duration(minutes: 9)))));
      expect(app.evening.current, Segment.lights);
      await app.wait(12);
      expect(app.evening.current, Segment.lullaby, reason: 'ten seconds were left');
      await app.end();
    });

    testWidgets('closed for ten minutes or more, a new evening starts; tonight is saved as it goes', (tester) async {
      final now = DateTime(2026, 11, 15, 20, 30);
      final app = await TestApp.start(tester, at: now, game: Game(tonight: Tonight(used: const Duration(minutes: 7), index: 2, seen: now.subtract(const Duration(minutes: 10)))));
      expect(app.evening.index, 0);
      await app.wait(31);
      expect(app.game.tonight!.index, 0);
      expect(app.game.tonight!.used.inSeconds, closeTo(31, 2));
      await toLullaby(app);
      expect(app.game.tonight, isNull, reason: 'good night is said');
      await app.end();
    });
  });

  group('the back key', () {
    testWidgets('never closes the app in the middle of the evening; parent mode goes back to it', (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call.method);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      final app = await TestApp.start(tester);
      Future<void> back() async {
        await tester.binding.handlePopRoute();
        await app.settle(800);
      }

      await back();
      expect(app.location, '/');
      await app.tapKey('parent-corner', ms: 800);
      await back();
      expect(gateOpen(), isFalse, reason: 'the gate closes');
      await app.tapKey('parent-corner', ms: 800);
      await app.answerGate();
      expect(app.location, '/parent');
      await back();
      expect(app.location, '/');
      await toLullaby(app);
      await back();
      expect(app.evening.current, Segment.lullaby);
      app.change((g) => g.copyWith(settings: g.settings.copyWith(lullabyOnly: true)));
      app.go('/lullaby');
      await app.settle(800);
      await back();
      expect(app.location, '/lullaby');
      expect(calls, isNot(contains('SystemNavigator.pop')));
      await app.end();
    });
  });

  group('the gate\'s lock', () {
    testWidgets('grows from one minute to five, is kept when the app restarts, and ends after a right answer', (tester) async {
      var app = await TestApp.start(tester);
      // 0 is never right (the answer is six to eighteen): three wrong
      // answers take at most six taps, and taps while locked do nothing.
      Future<void> wrong3() async {
        for (var i = 0; i < 6; i++) {
          await tester.tap(find.byKey(const ValueKey('gate-key-0')));
          await tester.pump(const Duration(milliseconds: 200));
        }
      }

      await app.tapKey('parent-corner', ms: 800);
      await wrong3();
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('請等'), findsOneWidget);
      app.now = app.now.add(const Duration(minutes: 1, seconds: 1));
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('請等'), findsNothing);
      await wrong3();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('請等 5 分鐘再試。'), findsOneWidget);
      final saved = app.game, now = app.now;
      await app.end();
      app = await TestApp.start(tester, game: saved, at: now.add(const Duration(seconds: 30)));
      await app.tapKey('parent-corner', ms: 800);
      expect(find.textContaining('請等'), findsOneWidget, reason: 'kept in the file');
      app.now = app.now.subtract(const Duration(hours: 1));
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('請等'), findsNothing, reason: 'a clock moved back does not lock for good');
      app.now = app.now.add(const Duration(hours: 1, minutes: 6));
      await tester.pump(const Duration(seconds: 2));
      await app.answerGate();
      expect(app.location, '/parent');
      expect(app.game.gate.locks, 0, reason: 'a right answer starts again');
      await app.end();
    });
  });

  group('the voice and parent mode', () {
    testWidgets('the story stops while parent mode is open and reads the page again after', (tester) async {
      final settings = const Settings(level: Level.big).copyWith(off: {Segment.checklist}, order: [Segment.story, Segment.lights, Segment.sheep, Segment.breath, Segment.checklist]);
      final app = await TestApp.start(tester, game: Game(settings: settings), voice: SlowVoice(const Duration(seconds: 20)));
      await app.wait(3);
      final first = app.game.storyFor(app.now).pages(Level.big).first.lines;
      expect(app.voice.said, containsAll(first));
      await app.tapKey('parent-corner', ms: 800);
      await app.answerGate();
      expect(app.location, '/parent');
      final said = app.voice.said.length;
      await app.wait(90);
      expect(app.voice.said.length, said, reason: 'nothing is read behind parent mode');
      expect(app.evening.current, Segment.story, reason: 'the story waits');
      await app.tapKey('parent-close', ms: 800);
      await app.wait(3);
      expect(app.voice.said.sublist(said), containsAll(first), reason: 'the page is read again');
      await app.wait(200);
      await app.end();
    });

    testWidgets('the voice follows the parent\'s volume', (tester) async {
      final app = await TestApp.start(tester, game: const Game(settings: Settings(volume: 0.3)));
      expect(app.voice.level, 0.3);
      app.change((g) => g.copyWith(settings: g.settings.copyWith(volume: 0.9)));
      await app.settle();
      expect(app.voice.level, 0.9);
      await app.end();
    });

    testWidgets('a part going away does not cut the next part\'s first line', (tester) async {
      final app = await TestApp.start(tester);
      await app.wait(2);
      final stops = app.voice.stops;
      app.container.read(eveningProvider.notifier).set(app.evening.next());
      await app.wait(3);
      expect(app.voice.said.last, isNot(contains('刷牙')));
      expect(app.voice.stops, stops, reason: 'the checklist had finished speaking; the lights\' first line goes on');
      await app.end();
    });
  });

  group('tonight\'s parts changed in parent mode', () {
    testWidgets('count tonight: a part turned off goes, 「只要搖籃曲」 goes to the lullaby', (tester) async {
      final app = await TestApp.start(tester, game: Game(settings: const Settings().copyWith(off: {Segment.checklist})));
      expect(app.evening.current, Segment.lights);
      await app.tapKey('parent-corner', ms: 800);
      await app.answerGate();
      await tester.scrollUntilVisible(find.byKey(const ValueKey('part-lullaby')), 200, scrollable: find.byType(Scrollable).first);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 200));
      await app.settle();
      await app.tapKey('part-sheep');
      expect(app.game.settings.off, contains(Segment.sheep));
      await app.tapKey('parent-close', ms: 800);
      expect(app.location, '/');
      await app.wait(2);
      expect(app.evening.plan, isNot(contains(Segment.sheep)));
      expect(app.evening.current, Segment.lights, reason: 'the town on screen goes on');
      app.container.read(eveningProvider.notifier).set(app.evening.next());
      await app.wait(2);
      expect(app.evening.current, Segment.story, reason: 'the sheep were turned off');
      await app.tapKey('parent-corner', ms: 800);
      await app.answerGate();
      await tester.scrollUntilVisible(find.byKey(const ValueKey('lullaby-only')), 200, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.byKey(const ValueKey('lullaby-only')));
      await app.settle();
      await app.tapKey('lullaby-only');
      expect(app.game.settings.lullabyOnly, isTrue);
      await app.tapKey('parent-close', ms: 800);
      await app.wait(2);
      expect(app.location, '/lullaby', reason: 'only the lullaby from now on');
      expect(app.game.locked(app.now), isTrue);
      await app.end();
    });
  });

  test('Evening.replanned keeps the parts done and the part on screen', () {
    final e = Evening(plan: const [Segment.checklist, Segment.lights, Segment.sheep, Segment.story, Segment.lullaby], started: DateTime(2026, 11, 15, 20), index: 1);
    final r = e.replanned(const [Segment.lights, Segment.story, Segment.lullaby]);
    expect(r.plan, [Segment.checklist, Segment.lights, Segment.story, Segment.lullaby]);
    expect(r.current, Segment.lights);
    expect(e.differs(const [Segment.lights, Segment.sheep, Segment.story, Segment.lullaby]), isFalse);
    expect(e.replanned(const [Segment.lullaby]).current, Segment.lullaby);
  });
}
