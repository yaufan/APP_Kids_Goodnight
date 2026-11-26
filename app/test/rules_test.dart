import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goodnight_town/core/content.dart';
import 'package:goodnight_town/core/evening.dart';
import 'package:goodnight_town/core/game.dart';
import 'package:goodnight_town/core/sounds.dart';
import 'package:goodnight_town/core/store.dart';
import 'package:goodnight_town/core/story.dart';

/// The rules of the evening (docs/design.md).
void main() {
  final evening = DateTime(2026, 11, 15, 20, 30);

  group('the evening', () {
    test('one fixed order, lullaby last; lights always there', () {
      expect(eveningPlan(const Settings()), [Segment.checklist, Segment.lights, Segment.sheep, Segment.story, Segment.breath, Segment.lullaby]);
      final off = const Settings().copyWith(off: {Segment.checklist, Segment.sheep, Segment.story, Segment.breath, Segment.lullaby});
      expect(eveningPlan(off), [Segment.lights]);
      expect(eveningPlan(const Settings(full: false)).first, Segment.lights, reason: 'the checklist is in the full version');
      expect(eveningPlan(const Settings(lullabyOnly: true)), [Segment.lullaby]);
      final moved = const Settings().moveUp(Segment.breath).moveUp(Segment.breath);
      expect(eveningPlan(moved), [Segment.checklist, Segment.lights, Segment.breath, Segment.sheep, Segment.story, Segment.lullaby]);
      expect(const Settings().moveUp(Segment.checklist).order, Segment.movable, reason: 'the first cannot move up');
    });

    test('parts follow each other, the time limit jumps to the lullaby', () {
      var e = Evening.start(const Settings(), evening);
      expect(e.current, Segment.checklist);
      e = e.next(passedBy: true);
      expect(e.current, Segment.lights);
      expect(e.skipped, [Segment.checklist]);
      e = e.next();
      expect(e.current, Segment.sheep);
      expect(e.overTime(evening.add(const Duration(minutes: 7, seconds: 59)), const Settings()), isFalse);
      expect(e.overTime(evening.add(const Duration(minutes: 8)), const Settings()), isTrue);
      e = e.timeUp();
      expect(e.current, Segment.lullaby);
      expect(e.saidGoodnight, isTrue);
      expect(e.skipped, [Segment.checklist, Segment.sheep, Segment.story, Segment.breath]);
      expect(e.overTime(evening.add(const Duration(hours: 1)), const Settings()), isFalse, reason: 'the lullaby is not counted');
      e = e.next();
      expect(e.over, isTrue);
      expect(e.current, isNull);
      expect(e.next(), same(e));
    });

    test('without a lullaby, time up is the good night', () {
      final s = const Settings().copyWith(off: {Segment.lullaby});
      final e = Evening.start(s, evening).timeUp();
      expect(e.over, isTrue);
      expect(e.saidGoodnight, isTrue);
    });

    test('nothing waits forever except the lullaby; the checklist waits a minute', () {
      expect(Evening.idleLimit(Segment.checklist, const Settings()), const Duration(seconds: 60));
      expect(Evening.idleLimit(Segment.lullaby, const Settings()), isNull);
      for (final s in Segment.values.where((s) => s != Segment.lullaby)) {
        expect(Evening.idleLimit(s, const Settings()), isNotNull, reason: s.name);
      }
      expect(Evening.idleLimit(Segment.story, const Settings(readStory: false))!, greaterThan(Evening.idleLimit(Segment.story, const Settings())!), reason: 'a parent reading takes longer');
    });
  });

  group('the one-hour lock', () {
    test('good night locks the app for an hour', () {
      final g = const Game().sayGoodnight(evening, used: const Duration(minutes: 7), skipped: [Segment.sheep]);
      expect(g.locked(evening), isTrue);
      expect(g.locked(evening.add(const Duration(minutes: 59, seconds: 59))), isTrue);
      expect(g.locked(evening.add(const Duration(hours: 1))), isFalse);
      expect(g.locked(evening.subtract(const Duration(minutes: 5))), isTrue, reason: 'a clock set back a little does not end the hour early');
      expect(g.locked(evening.subtract(const Duration(hours: 2))), isFalse, reason: 'a clock set back does not lock forever');
      expect(g.copyWith(unlock: true).locked(evening), isFalse);
      expect(const Game().locked(evening), isFalse);
    });

    test('the parent page sees the last seven days', () {
      var g = const Game();
      for (var d = 0; d < 9; d++) {
        final night = evening.subtract(Duration(days: d));
        g = g.sayGoodnight(night, used: Duration(minutes: 6 + d % 2), skipped: d.isEven ? [Segment.breath] : [Segment.sheep, Segment.breath]);
      }
      // A second goodnight the same night replaces the first.
      g = g.sayGoodnight(evening.add(const Duration(hours: 2)), used: const Duration(minutes: 6), skipped: [Segment.breath]);
      final w = g.week(evening.add(const Duration(hours: 2)));
      expect(w.nights, 7);
      expect(w.mostSkipped, Segment.breath);
      expect(w.averageMinutes, closeTo((6 * 4 + 7 * 3) / 7, 0.01));
      expect(g.history.length, lessThanOrEqualTo(Game.historyKept));
    });

    test('an evening past midnight is still the same night', () {
      expect(nightNumber(DateTime(2026, 11, 16, 1, 30)), nightNumber(DateTime(2026, 11, 15, 20)));
      expect(nightNumber(DateTime(2026, 11, 16, 20)), nightNumber(DateTime(2026, 11, 15, 20)) + 1);
    });
  });

  group('the story', () {
    test('every page reads as Chinese without a hole, and fits the time', () {
      for (final level in Level.values) {
        var longest = Duration.zero;
        for (final s in Story.all) {
          final pages = s.pages(level);
          expect(pages.length, level.pages);
          for (final p in pages) {
            expect(p.lines.length, inInclusiveRange(2, 5), reason: '${s.key} ${p.text}');
            for (final l in p.lines) {
              expect(l, isNot(contains('{')), reason: s.key);
              expect(l.length, lessThanOrEqualTo(16), reason: 'short lines for big letters: $l');
            }
          }
          final t = Story.readingTime(pages);
          if (t > longest) longest = t;
          expect(t, lessThanOrEqualTo(Story.longest(level)), reason: '${s.key} at ${level.name}');
        }
        expect(longest, greaterThan(Duration(seconds: level == Level.small ? 30 : 60)), reason: 'not too short either');
      }
    });

    test('there are many stories and six fixed ones', () {
      expect(Place.values.length, 6);
      expect(Happening.values.length, 10);
      expect(Ending.values.length, 4);
      expect(Story.all.length, greaterThan(1000));
      expect(Story.fixed.toSet().length, 6);
      for (final s in Story.fixed) {
        expect(Story.fits(s.thing, s.ending), isTrue, reason: s.key);
        expect(Story.fromKey(s.key), s);
      }
      expect(Story.fromKey('nothing'), isNull);
      expect(Story.fromKey('cat.roof.star.nothing'), isNull);
    });

    test('the same all evening, never the same two nights running', () {
      final night = nightNumber(evening);
      for (final full in [true, false]) {
        Story? last;
        for (var n = night; n < night + 60; n++) {
          final s = Story.tonight(n, full: full, last: last);
          expect(Story.tonight(n, full: full, last: last), s, reason: 'deterministic');
          expect(s, isNot(last), reason: 'night $n');
          if (full && last != null) expect(s.who, isNot(last.who));
          if (!full) expect(Story.fixed, contains(s));
          last = s;
        }
      }
      var g = const Game();
      final s = g.storyFor(evening);
      g = g.toldStory(s, evening);
      expect(g.storyFor(evening.add(const Duration(minutes: 30))), s, reason: 'the same story again tonight');
      expect(g.storyFor(evening.add(const Duration(days: 1))), isNot(s));
    });
  });

  group('counting and breathing', () {
    test('small and big', () {
      expect(Level.small.sheep, 5);
      expect(Level.big.sheep, 10);
      expect(Level.small.breaths, 3);
      expect(Level.big.breaths, 5);
      expect(Level.small.lights.length, 6);
      expect(Level.big.lights.length, inInclusiveRange(10, 12));
      expect(Breath.inhale, const Duration(seconds: 4));
      expect(Breath.exhale, const Duration(seconds: 6));
      expect([for (var i = 1; i <= 10; i++) zhNumber(i)].join(), '一二三四五六七八九十');
      expect(Light.values.where((l) => l.animal != null).length, 7);
      expect(Light.rabbit.goodnight, '小兔子睡了，晚安～');
    });
  });

  group('the lullaby', () {
    test('plays for the minutes chosen and gets quieter over the last two', () {
      final c = LullabyClock(evening, 20);
      expect(c.minutesLeft(evening), 20);
      expect(c.minutesLeft(evening.add(const Duration(minutes: 1, seconds: 30))), 19);
      expect(c.volume(evening.add(const Duration(minutes: 17))), 1);
      expect(c.volume(evening.add(const Duration(minutes: 19))), closeTo(0.5, 0.001));
      expect(c.done(evening.add(const Duration(minutes: 19, seconds: 59))), isFalse);
      expect(c.done(evening.add(const Duration(minutes: 20))), isTrue);
      expect(c.volume(evening.add(const Duration(minutes: 25))), 0);
    });

    test('free phones have four sounds; the music box has three tunes', () {
      expect(Lullaby.free, [Lullaby.musicBox, Lullaby.humming, Lullaby.rain, Lullaby.waves]);
      expect(const Settings(lullaby: Lullaby.fan, full: false).sound, Lullaby.musicBox);
      expect(const Settings(lullaby: Lullaby.fan).sound, Lullaby.fan);
      expect({for (var n = 0; n < 3; n++) Music.of(Lullaby.musicBox, n)}.length, 3);
      expect({for (var n = 0; n < 2; n++) Music.of(Lullaby.humming, n)}.length, 2);
      expect(Music.street(0), Music.dusk);
      expect(Music.street(0.5), Music.duskQuiet);
      expect(Music.street(1), Music.wind);
    });
  });

  group('saving', () {
    test('everything comes back as it was saved', () {
      final s = const Settings().copyWith(
        level: Level.big,
        minutes: 10,
        off: {Segment.sheep},
        order: const [Segment.lights, Segment.checklist, Segment.story, Segment.sheep, Segment.breath],
        lullaby: Lullaby.rain,
        lullabyMinutes: 30,
        lullabyOnly: true,
        readStory: false,
        slowVoice: false,
        dim: 0.4,
        volume: 0.5,
        sounds: false,
        voice: false,
        full: false,
      );
      final g = Game(settings: s).sayGoodnight(evening, used: const Duration(minutes: 7), skipped: [Segment.story]).toldStory(Story.fixed[2], evening);
      final back = Game.fromJson(jsonDecode(jsonEncode(g.toJson())) as Map<String, dynamic>);
      expect(back.toJson(), g.toJson());
      expect(back.locked(evening), isTrue);
      expect(back.settings.order, s.order);
    });

    test('a broken or strange file gives the defaults, never a crash', () {
      expect(Game.fromJson(null).toJson(), const Game().toJson());
      final odd = Game.fromJson({
        'settings': {'level': 'huge', 'minutes': 99, 'off': ['lights', 'nothing', 3], 'order': ['story', 'story', 'lullaby', 7], 'lullaby': 'x', 'lullabyMinutes': 7, 'dim': 5, 'volume': -1, 'full': 'yes'},
        'goodnightAt': 'not a date',
        'lastStory': 'a.b.c.d',
        'history': [1, {'night': 'x'}, {'night': 3, 'seconds': 60, 'skipped': ['sheep', 'nope']}],
      });
      expect(odd.settings.level, Level.small);
      expect(odd.settings.minutes, 8);
      expect(odd.settings.off, isEmpty, reason: 'the lights cannot be turned off');
      expect(odd.settings.order.toSet(), Segment.movable.toSet());
      expect(odd.settings.order.length, Segment.movable.length);
      expect(odd.settings.order.first, Segment.story);
      expect(odd.settings.lullabyMinutes, 20);
      expect(odd.settings.dim, Settings.maxDim);
      expect(odd.settings.volume, 0.2);
      expect(odd.settings.full, isTrue);
      expect(odd.goodnightAt, isNull);
      expect(odd.lastStory, isNull);
      expect(odd.history.single.skipped, [Segment.sheep]);
    });

    test('the file store keeps the last good copy', () async {
      final dir = await Directory.systemTemp.createTemp('goodnight_store');
      addTearDown(() => dir.delete(recursive: true));
      final store = FileStore(dir);
      expect(await store.read(), isNull);
      store.write(const Game(settings: Settings(minutes: 5)).toJson());
      store.write(const Game(settings: Settings(minutes: 10)).toJson());
      await store.flush();
      expect(Game.fromJson(await store.read()).settings.minutes, 10);
      File('${dir.path}/goodnight_town.json').writeAsStringSync('{broken');
      expect(Game.fromJson(await store.read()).settings.minutes, 5, reason: 'the copy from the save before');
    });
  });
}
