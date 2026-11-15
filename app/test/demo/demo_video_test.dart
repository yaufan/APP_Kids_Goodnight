// Records a demo video of 晚安小鎮: a scripted child (a white dot where the
// finger is) with a caption under the phone screen; the loops and sounds the
// app asked for are written down and mixed in afterwards by
// tools/demo_audio.py.
//
//   flutter test test/demo/demo_video_test.dart --dart-define=DEMO=true
//   python3 ../tools/demo_audio.py
//
// Needs ffmpeg; writes build/demo/demo.mp4, chapters.txt and sounds.txt.
// Skipped in normal test runs.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodnight_town/app/app.dart';
import 'package:goodnight_town/core/content.dart';
import 'package:goodnight_town/core/game.dart';
import 'package:goodnight_town/core/providers.dart';
import 'package:goodnight_town/core/screen.dart';
import 'package:goodnight_town/core/sounds.dart';
import 'package:goodnight_town/core/store.dart';
import 'package:goodnight_town/core/voice.dart';
import 'package:goodnight_town/features/parent/parent_gate.dart';

import '../helpers.dart' show loadFonts;

const _phone = Size(390, 844);
const _captionHeight = 84.0;
const _fps = 10;
const _demo = bool.fromEnvironment('DEMO');

/// The loops and the sounds asked for, with the frame they were asked at.
class _Recording implements Sounds {
  _Recording(this.frame);

  final int Function() frame;
  final lines = <String>[];
  final _holders = MusicHolders();
  (Music?, double)? _playing;

  @override
  set volume(double v) {}

  @override
  set effects(bool on) {}

  @override
  void play(String sfx) => lines.add('${frame()} sfx $sfx');

  @override
  void hold(Object owner, Music? music, {double level = 1}) {
    _holders.hold(owner, music, level);
    _changed();
  }

  @override
  void release(Object owner) {
    _holders.release(owner);
    _changed();
  }

  void _changed() {
    final now = (_holders.current, (_holders.level * 10).round() / 10);
    if (now == _playing) return;
    _playing = now;
    lines.add('${frame()} music ${now.$1?.file ?? '-'} ${now.$2}');
  }
}

/// Reading takes a little time, as a real voice would (a little faster).
class _DemoVoice implements Voice {
  @override
  set slow(bool on) {}

  @override
  Future<void> say(String text) async {}

  @override
  Future<void> read(List<String> lines, {Duration pause = const Duration(seconds: 1)}) =>
      Future<void>.delayed(Duration(milliseconds: lines.fold<int>(0, (a, l) => a + l.length * 110 + 300)));

  @override
  Future<void> stop() async {}
}

void main() {
  testWidgets('demo video', skip: !_demo, (tester) async {
    await tester.runAsync(loadFonts);
    tester.view.physicalSize = Size(_phone.width * 3, (_phone.height + _captionHeight) * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    var frameCount = 0;
    var now = DateTime(2026, 11, 15, 20, 30);
    final track = _Recording(() => frameCount);
    final finger = ValueNotifier<Offset?>(null);
    final caption = ValueNotifier<String>('');
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(children: [
          SizedBox.fromSize(
            size: _phone,
            child: MediaQuery(
              data: const MediaQueryData(size: _phone, devicePixelRatio: 3, padding: EdgeInsets.only(top: 24)),
              child: Stack(children: [
                ProviderScope(
                  overrides: [
                    storeProvider.overrideWithValue(MemoryStore()),
                    savedGameProvider.overrideWithValue(const Game()),
                    soundsProvider.overrideWithValue(track),
                    voiceProvider.overrideWithValue(_DemoVoice()),
                    screenProvider.overrideWithValue(RecordingScreen()),
                    clockProvider.overrideWithValue(() => now),
                  ],
                  child: const GoodnightApp(),
                ),
                IgnorePointer(child: ValueListenableBuilder(valueListenable: finger, builder: (_, at, _) => _Finger(at))),
              ]),
            ),
          ),
          SizedBox(
            width: _phone.width,
            height: _captionHeight,
            child: ColoredBox(
              color: const Color(0xFF2B3070),
              child: Center(
                child: ValueListenableBuilder(
                  valueListenable: caption,
                  builder: (_, text, _) => Text(text, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Huninn', color: Color(0xFFFFE6A6), fontSize: 17, height: 1.35)),
                ),
              ),
            ),
          ),
        ]),
      ),
    ));

    final rec = (await tester.runAsync(() => _Recorder.start(key)))!;
    final marks = <String>[];
    void mark(String name) => marks.add('$name $frameCount');
    Future<void> frames(int n) async {
      for (var i = 0; i < n; i++) {
        frameCount++;
        await tester.runAsync(() async {
          await rec.capture();
          await Future<void>.delayed(const Duration(milliseconds: 15));
        });
        now = now.add(const Duration(milliseconds: 1000 ~/ _fps));
        await tester.pump(const Duration(milliseconds: 1000 ~/ _fps));
      }
    }

    Future<void> seconds(double s) => frames((s * _fps).round());
    Future<void> touch(Offset at) async {
      finger.value = at;
      await frames(2);
      await tester.tapAt(at);
      await frames(2);
      finger.value = null;
    }

    Future<void> tapKey(String k) => touch(tester.getCenter(find.byKey(ValueKey(k)).last));
    Future<void> holdKey(String k, double s) async {
      final c = tester.getCenter(find.byKey(ValueKey(k)).last);
      finger.value = c;
      final g = await tester.startGesture(c);
      await seconds(s);
      await g.up();
      finger.value = null;
    }

    ProviderContainer container() => ProviderScope.containerOf(tester.element(find.byType(GoodnightApp)));

    // The checklist.
    mark('checklist');
    caption.value = '晚安小鎮：睡前最後 5～8 分鐘\n目的不是玩，是帶小朋友去睡覺';
    await seconds(3.5);
    caption.value = '晚安清單：刷牙、尿尿、喝水、抱抱\n真的做完了，回來點一下';
    for (final c in Check.values) {
      await tapKey('check-${c.name}');
      await seconds(1.4);
    }
    await seconds(5);

    // The lights.
    mark('lights');
    caption.value = '關燈巡邏：黃昏的台灣小街\n點一下亮著的窗戶和燈';
    await seconds(3);
    final lights = container().read(gameProvider).settings.level.lights;
    for (final (i, l) in lights.indexed) {
      if (i == 1) caption.value = '燈慢慢暗下來，動物打哈欠、睡著了';
      if (i == 3) caption.value = '每關一盞，小鎮暗一點、安靜一點\n（2～3 歲 6 盞燈，4～5 歲 12 盞）';
      await tapKey('light-${l.name}');
      await seconds(2.6);
    }
    caption.value = '大家都睡了。';
    await seconds(9.5);

    // Sheep.
    mark('sheep');
    caption.value = '數羊：點一下，一隻小羊慢慢跳過柵欄\nAPP 慢慢念「一、二、三」';
    await seconds(2);
    for (var i = 0; i < container().read(gameProvider).settings.level.sheep; i++) {
      await touch(const Offset(195, 500));
      await seconds(4.2);
    }
    await seconds(7);

    // The story.
    mark('story');
    caption.value = '晚安故事：人寫好的片段組起來\n每晚不一樣，APP 用國語慢慢念';
    await seconds(9);
    caption.value = '家長也可以關掉念故事，自己念\n（字很大，暗暗的也看得清楚）';
    await seconds(10);

    // The moon.
    mark('breath');
    caption.value = '呼吸小月亮：月亮先示範一次';
    await seconds(5);
    caption.value = '按住月亮吸氣（變大）\n放開，慢慢吐氣（變小）';
    for (var i = 0; i < container().read(gameProvider).settings.level.breaths; i++) {
      await holdKey('moon', 3.6);
      await seconds(i == 2 ? 6 : 3.5);
    }
    await seconds(5);

    // The lullaby.
    mark('lullaby');
    caption.value = '搖籃曲：音樂盒、哼歌、雨聲、海浪、風扇、心跳\n10、20、30 分鐘';
    await seconds(3);
    await tapKey('sound-humming');
    await seconds(2);
    await tapKey('sound-musicBox');
    await seconds(2.5);
    mark('black');
    caption.value = '沒人碰：選項淡掉，只剩月亮\n然後整個螢幕慢慢變黑';
    now = now.add(const Duration(seconds: 20));
    await seconds(4);
    now = now.add(const Duration(seconds: 12));
    await seconds(4);
    now = now.add(const Duration(seconds: 20));
    caption.value = '螢幕黑著但不睡，不會發光\n手機可以蓋起來放旁邊';
    await seconds(4.5);

    // The end.
    mark('goodnight');
    caption.value = '時間到了：最後兩分鐘聲音慢慢變小\nAPP 說「換你去睡了」，自己關掉';
    now = now.add(const Duration(minutes: 19, seconds: 30));
    await seconds(9);
    caption.value = '關掉以後一小時內再打開\n只有黑畫面和搖籃曲（不會「再玩一次」）';
    await seconds(3.5);

    // Parent mode.
    mark('parent');
    caption.value = '家長答對題目，才能進家長模式';
    const digits = {'零': 0, '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9};
    await tapKey('parent-corner');
    await seconds(1.2);
    final parts = (find.textContaining('加').evaluate().first.widget as Text).data!.split(' ');
    for (final d in '${digits[parts[0]]! + digits[parts[2]]!}'.split('')) {
      await tapKey('gate-key-$d');
      await frames(3);
    }
    await seconds(1.5);
    caption.value = '家長模式：年齡、整晚幾分鐘\n今晚做哪些段落、順序';
    await seconds(3);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await seconds(2.5);
    caption.value = '搖籃曲的聲音和時間、「只要搖籃曲」\n念故事、螢幕再暗一點、最近七天';
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await seconds(3.5);
    caption.value = '';
    mark('end');
    await seconds(0.5);

    expect(ParentPass.take(), isFalse);
    await tester.runAsync(() async {
      await rec.finish();
      File('build/demo/chapters.txt').writeAsStringSync('${marks.join('\n')}\n');
      File('build/demo/sounds.txt').writeAsStringSync('fps $_fps\nframes $frameCount\n${track.lines.join('\n')}\n');
    });
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }, timeout: const Timeout(Duration(minutes: 40)));
}

class _Finger extends StatelessWidget {
  const _Finger(this.at);

  final Offset? at;

  @override
  Widget build(BuildContext context) {
    final p = at;
    if (p == null) return const SizedBox.expand();
    return Stack(children: [
      Positioned(
        left: p.dx - 22,
        top: p.dy - 22,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.45),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 3),
          ),
        ),
      ),
    ]);
  }
}

/// Streams frames of [key]'s boundary into ffmpeg.
class _Recorder {
  _Recorder(this._key, this._ffmpeg);

  final GlobalKey _key;
  final Process _ffmpeg;

  static Future<_Recorder> start(GlobalKey key) async {
    Directory('build/demo').createSync(recursive: true);
    final size = Size(_phone.width * 2, (_phone.height + _captionHeight) * 2);
    final ffmpeg = await Process.start('ffmpeg', [
      '-y', '-loglevel', 'error',
      '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '${size.width.toInt()}x${size.height.toInt()}', '-r', '$_fps', '-i', '-',
      '-vf', 'fps=30', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '24', '-movflags', '+faststart', 'build/demo/demo_silent.mp4',
    ]);
    ffmpeg.stderr.listen(stderr.add);
    return _Recorder(key, ffmpeg);
  }

  Future<void> capture() async {
    final boundary = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    _ffmpeg.stdin.add(bytes!.buffer.asUint8List());
    await _ffmpeg.stdin.flush();
  }

  Future<void> finish() async {
    await _ffmpeg.stdin.flush();
    await _ffmpeg.stdin.close();
    final code = await _ffmpeg.exitCode;
    if (code != 0) throw StateError('ffmpeg failed ($code)');
  }
}
