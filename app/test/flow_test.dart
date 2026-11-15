import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodnight_town/core/content.dart';
import 'package:goodnight_town/core/game.dart';
import 'package:goodnight_town/core/sounds.dart';
import 'package:goodnight_town/features/parent/parent_gate.dart';

import 'helpers.dart';

/// A whole evening as a child (and a parent) would go through it, on a
/// phone and a tablet, with screenshots in `build/screenshots/<device>/`
/// (docs/design.md).
void main() {
  setUpAll(loadFonts);

  for (final MapEntry(key: device, value: (size, ratio, level)) in {
    'phone': (const Size(1080, 2340), 2.75, Level.small),
    'tablet': (const Size(1620, 2160), 2.0, Level.big),
  }.entries) {
    testWidgets('an evening in the town ($device)', (tester) async {
      final app = await TestApp.start(tester, size: size, ratio: ratio, game: Game(settings: Settings(level: level)));
      Future<void> shot(String name) => shoot(tester, device, name);

      // 晚安清單: tap what was done for real.
      expect(app.location, '/');
      expect(app.evening.current, Segment.checklist);
      expect(app.screen.awake, isTrue, reason: 'the screen stays on through the evening');
      await app.wait(1.5);
      await shot('01_checklist');
      await app.tapKey('check-teeth');
      await app.tapKey('check-potty', ms: 1500);
      expect(app.sounds.played, contains('yawn_small'));
      await shot('02_checklist_two');
      await app.tapKey('check-water');
      await app.tapKey('check-hug');
      await app.wait(2);
      expect(app.voice.said, contains('都做好了，我們去幫大家關燈。'));
      await app.wait(5);

      // 關燈巡邏: every lit window and lamp.
      expect(app.evening.current, Segment.lights);
      expect(app.sounds.music, Music.dusk);
      await app.wait(2);
      await shot('03_lights');
      final lit = level.lights;
      await app.tapKey('light-${lit[1].name}', ms: 600);
      await app.wait(1.2);
      await shot('04_lights_yawn');
      expect(app.sounds.played, contains(lit[1].animal!.yawn));
      await app.wait(2);
      expect(app.voice.said, contains(lit[1].goodnight));
      await shot('05_lights_one_off');
      app.sounds.played.clear();
      await app.tapKey('light-${lit[1].name}');
      expect(app.sounds.played, ['puff_soft'], reason: 'a dark window only goes 噗');
      for (final l in lit.skip(2).take(lit.length ~/ 2)) {
        await app.tapKey('light-${l.name}', ms: 700);
      }
      await app.wait(2);
      await shot('06_lights_half');
      for (final l in [lit[0], ...lit.skip(2 + lit.length ~/ 2)]) {
        await app.tapKey('light-${l.name}', ms: 700);
      }
      expect(app.sounds.music, Music.wind, reason: 'all dark: only the wind');
      await app.wait(5);
      expect(app.voice.said, contains('大家都睡了。'));
      await shot('07_lights_all_dark');
      await app.wait(6);

      // 數羊: tap, a sheep hops; tap again for the next.
      expect(app.evening.current, Segment.sheep);
      await app.wait(1.5);
      await shot('08_sheep');
      for (var i = 0; i < level.sheep; i++) {
        await app.tapKey('sheep', ms: 1500);
        if (i == 1) await shot('09_sheep_jump');
        await app.wait(2);
        expect(app.voice.said.last, zhNumber(i + 1));
        if (i == 2) await shot('10_sheep_three');
      }
      await app.wait(3);
      await shot('11_sheep_all');
      await app.wait(5);

      // 晚安故事: the app reads; turn the pages.
      expect(app.evening.current, Segment.story);
      await app.wait(2);
      await shot('12_story');
      final story = app.game.storyFor(app.now);
      final pages = story.pages(level);
      expect(app.voice.said, containsAll(pages.first.lines));
      for (var p = 1; p < pages.length; p++) {
        await app.tapLabel('下一頁', ms: 1500);
        if (p == pages.length - 1) await shot('13_story_last');
      }
      await app.tapLabel('晚安');
      await app.wait(3.5);

      // 呼吸小月亮: the moon shows once, then hold and let go.
      expect(app.evening.current, Segment.breath);
      await app.wait(5);
      await shot('14_breath_in');
      await app.wait(9);
      for (var i = 0; i < level.breaths; i++) {
        await app.hold('moon', 3);
        if (i == 0) await shot('15_breath_out');
        await app.wait(3);
      }
      await app.wait(12);

      // 搖籃曲: choose, then the screen goes black.
      expect(app.evening.current, Segment.lullaby);
      expect(app.game.locked(app.now), isTrue, reason: 'good night is said');
      expect(app.game.history.single.skipped, isEmpty);
      await app.wait(2);
      await shot('16_lullaby');
      await app.tapKey('sound-rain');
      expect(app.sounds.music, Music.rain);
      await app.tapKey('minutes-10');
      await app.wait(25);
      await shot('17_lullaby_moon');
      await app.wait(40);
      expect(app.screen.dimmed, isTrue, reason: 'black: the window turned right down');
      await shot('18_lullaby_black');
      app.now = app.now.add(const Duration(minutes: 8));
      await app.wait(2);
      expect(app.sounds.level, lessThan(1), reason: 'quieter over the last two minutes');
      app.now = app.now.add(const Duration(minutes: 1));
      await app.wait(3);
      expect(app.evening.over, isTrue);
      await shot('19_goodnight');
      expect(app.voice.said, contains('換你去睡了，晚安。'));
      await app.wait(8);
      expect(app.screen.closed, 1, reason: 'the app closes itself');
      expect(app.location, '/ended');

      // Parent mode, through the gate.
      await app.tapKey('parent-corner', ms: 800);
      await app.answerGate();
      expect(app.location, '/parent');
      await shot('20_parent');
      await app.tapKey('level-${Level.values.firstWhere((l) => l != level).name}');
      expect(app.game.settings.level, isNot(level));
      await app.end();
    }, timeout: const Timeout(Duration(minutes: 12)));
  }

  testWidgets('opened again within the hour: only the black screen and the lullaby', (tester) async {
    final at = DateTime(2026, 11, 15, 21, 0);
    final saved = const Game().sayGoodnight(at, used: const Duration(minutes: 7));
    final app = await TestApp.start(tester, game: saved, at: at.add(const Duration(minutes: 20)));
    expect(app.location, '/lullaby');
    await app.wait(12);
    expect(app.screen.awake, isTrue);
    expect(app.sounds.music, isNotNull);
    await shoot(tester, 'phone', '21_reopened');
    // A parent lifts it.
    await app.tapKey('parent-corner', ms: 800);
    await app.answerGate();
    await app.tapKey('restart', ms: 800);
    expect(app.location, '/');
    expect(app.game.locked(app.now), isFalse);
    expect(ParentPass.take(), isFalse);
    await app.end();
  });
}
