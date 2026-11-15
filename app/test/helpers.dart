import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodnight_town/app/app.dart';
import 'package:goodnight_town/core/evening.dart';
import 'package:goodnight_town/core/game.dart';
import 'package:goodnight_town/core/providers.dart';
import 'package:goodnight_town/core/screen.dart';
import 'package:goodnight_town/core/sounds.dart';
import 'package:goodnight_town/core/store.dart';
import 'package:goodnight_town/core/voice.dart';

final shotKey = GlobalKey();

/// The app on a phone screen, starting from [game] at [now] (an evening).
class TestApp {
  TestApp(this.tester, this.store, this.sounds, this.voice, this.screen, this.now);

  final WidgetTester tester;
  final MemoryStore store;
  final RecordingSounds sounds;
  final RecordingVoice voice;
  final RecordingScreen screen;
  DateTime now;

  ProviderContainer get container => ProviderScope.containerOf(tester.element(find.byType(GoodnightApp)));
  Game get game => container.read(gameProvider);
  Evening get evening => container.read(eveningProvider);
  void change(Game Function(Game g) f) => container.read(gameProvider.notifier).change(f);

  static Future<TestApp> start(WidgetTester tester, {Game game = const Game(), Size size = const Size(1080, 2340), double ratio = 2.75, DateTime? at}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);
    final app = TestApp(tester, MemoryStore(), RecordingSounds(), RecordingVoice(), RecordingScreen(), at ?? DateTime(2026, 11, 15, 20, 30));
    await tester.pumpWidget(RepaintBoundary(
      key: shotKey,
      child: ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(app.store),
          savedGameProvider.overrideWithValue(game),
          soundsProvider.overrideWithValue(app.sounds),
          voiceProvider.overrideWithValue(app.voice),
          screenProvider.overrideWithValue(app.screen),
          clockProvider.overrideWithValue(() => app.now),
        ],
        child: const GoodnightApp(),
      ),
    ));
    await app.settle();
    return app;
  }

  void go(String location) => container.read(routerProvider).go(location);

  /// The page on top (parent mode is pushed over the evening).
  String get location => container.read(routerProvider).state.matchedLocation;

  /// Lets the pictures load and [ms] milliseconds pass (on the app's clock too).
  Future<void> settle([int ms = 400]) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      now = now.add(Duration(milliseconds: ms ~/ 6));
      await tester.pump(Duration(milliseconds: ms ~/ 6));
    }
  }

  /// [seconds] pass, a second at a time (the evening's timers tick).
  Future<void> wait(double seconds) async {
    var left = (seconds * 1000).round();
    while (left > 0) {
      final step = left > 1000 ? 1000 : left;
      await settle(step);
      left -= step;
    }
  }

  Future<void> tapKey(String key, {int ms = 400}) async {
    await tester.tap(find.byKey(ValueKey(key)).last, warnIfMissed: false);
    await settle(ms);
  }

  Future<void> tapLabel(String label, {int ms = 400}) async {
    await tester.tap(find.bySemanticsLabel(label).last, warnIfMissed: false);
    await settle(ms);
  }

  /// Holds a finger on [key] for [seconds], then lets go.
  Future<void> hold(String key, double seconds) async {
    final g = await tester.startGesture(tester.getCenter(find.byKey(ValueKey(key)).last));
    await wait(seconds);
    await g.up();
    await settle(200);
  }

  /// Answers the parent gate (the question is written in characters).
  Future<void> answerGate() async {
    const digits = {'零': 0, '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9};
    final parts = (find.textContaining('加').evaluate().first.widget as Text).data!.split(' ');
    for (final d in '${digits[parts[0]]! + digits[parts[2]]!}'.split('')) {
      await tester.tap(find.byKey(ValueKey('gate-key-$d')));
      await settle(200);
    }
    await settle(800);
  }

  Future<void> end() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }
}

/// Real fonts for screenshots instead of the test font's boxes.
Future<void> loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/home/user/flutter';
  final fonts = {
    'MaterialIcons': ['$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'],
    'Huninn': ['assets/fonts/jf-openhuninn-2.1.ttf'],
    'Roboto': ['assets/fonts/jf-openhuninn-2.1.ttf'],
  };
  for (final MapEntry(key: family, value: paths) in fonts.entries) {
    final loader = FontLoader(family);
    for (final path in paths.where((p) => File(p).existsSync())) {
      loader.addFont(File(path).readAsBytes().then(ByteData.sublistView));
    }
    await loader.load();
  }
}

Future<void> shoot(WidgetTester tester, String device, String name) => tester.runAsync(() async {
      final boundary = shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: device == 'phone' ? 2 : 1.5);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/screenshots/$device/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
