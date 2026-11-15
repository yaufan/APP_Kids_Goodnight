import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:goodnight_town/app/widgets.dart';
import 'package:goodnight_town/core/content.dart';
import 'package:goodnight_town/core/sounds.dart';
import 'package:goodnight_town/core/story.dart';
import 'package:goodnight_town/core/street_layout.dart';

/// Every picture and sound the program asks for exists (design/art,
/// design/sounds), the street's pieces fit together, and nothing uses what
/// flutter_svg cannot draw.
void main() {
  bool has(String path) => File(path).existsSync();

  Size viewBox(String path) {
    final m = RegExp(r'viewBox="0 0 ([0-9.]+) ([0-9.]+)"').firstMatch(File(path).readAsStringSync())!;
    return Size(double.parse(m.group(1)!), double.parse(m.group(2)!));
  }

  test('every picture is drawn', () {
    final want = [
      ArtPath.street,
      ArtPath.grille,
      for (final l in Light.values) ArtPath.glow(l),
      for (final a in Animal.values) ...[ArtPath.animal(a), ArtPath.animal(a, asleep: true)],
      ArtPath.moon,
      ArtPath.moonFull,
      ArtPath.zz,
      ArtPath.meadow,
      ArtPath.sheep,
      ArtPath.sheepSleep,
      for (final p in Place.values) ArtPath.place(p.name),
      for (final t in Happening.values) ArtPath.thing(t.name),
      for (final c in Check.values) ArtPath.check(c),
      for (final l in Lullaby.values) ArtPath.lullaby(l),
      for (final u in ['close', 'speak', 'next', 'lock']) ArtPath.ui(u),
    ];
    expect([for (final p in want) if (!has(p)) p], isEmpty);
  });

  test('the street: every light has its place, inside the part every phone shows, and no two overlap', () {
    expect(lightPlaces.keys.toSet(), Light.values.toSet());
    final street = Offset.zero & streetSize;
    for (final l in Light.values) {
      final p = lightPlaces[l]!;
      expect(streetCore.contains(p.tap.topLeft) && streetCore.contains(p.tap.bottomRight), isTrue, reason: '${l.name} can be tapped on a phone');
      expect(street.contains(p.art.topLeft) && street.contains(p.art.bottomRight - const Offset(.01, .01)), isTrue, reason: l.name);
      expect(viewBox(ArtPath.glow(l)), p.art.size, reason: 'glow_${l.name}.svg is drawn for its box');
      expect(p.tap.width * 0.98 >= 40 && p.tap.height * 0.98 >= 40, isTrue, reason: '${l.name}: a big enough target for a small finger');
      expect(p.animal != null, l.animal != null && l != Light.window, reason: l.name);
      if (p.animal != null) expect(p.art.contains(p.animal!.center), isTrue, reason: l.name);
      for (final o in Light.values.where((o) => o.index > l.index)) {
        expect(p.tap.overlaps(lightPlaces[o]!.tap), isFalse, reason: '${l.name} and ${o.name}');
      }
    }
    for (final l in Level.values) {
      expect(l.lights.toSet().length, l.lights.length);
    }
  });

  test('every sound the app plays is there, and they are not too big', () {
    final sfx = [
      'tap', 'puff', 'puff_soft', 'yawn_small', 'sheep_hop', 'baa', 'page', 'breath_in', 'breath_out', 'goodnight',
      for (final a in Animal.values) a.yawn,
      for (final m in Music.values) m.file,
    ];
    expect([for (final s in sfx) if (!has('assets/sounds/$s.wav')) s], isEmpty);
    final total = Directory('assets/sounds').listSync().whereType<File>().fold<int>(0, (a, f) => a + f.lengthSync());
    expect(total, lessThan(15 * 1024 * 1024));
  });

  test('no picture uses what flutter_svg cannot draw, and none is too big', () {
    final bad = <String>[];
    for (final f in Directory('assets/art').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.svg')) continue;
      final text = f.readAsStringSync();
      if (f.lengthSync() > 70 * 1024) bad.add('${f.path} too big');
      for (final no in ['<filter', '<mask', '<style', 'style=', '<text', '<image', '<pattern', 'mix-blend', '<clipPath', '<use']) {
        if (text.contains(no)) bad.add('${f.path} uses $no');
      }
      if (!text.trimRight().endsWith('</svg>')) bad.add('${f.path} is cut off');
      if (!text.startsWith('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ')) bad.add('${f.path} has no plain viewBox');
    }
    expect(bad, isEmpty);
  });

  test('the animals are drawn with the colours the app paints', () {
    for (final a in Animal.values) {
      final awake = File(ArtPath.animal(a)).readAsStringSync();
      final asleep = File(ArtPath.animal(a, asleep: true)).readAsStringSync();
      expect(awake, contains('#BODY'));
      expect(awake, contains('#EYE'));
      expect(asleep, contains('#LID'));
      for (final paint in [AnimalPaint.lit, AnimalPaint.dark, AnimalPaint.story]) {
        expect(paint.keys.toSet(), {'#BODY', '#EYE', '#LID'});
      }
    }
  });
}
