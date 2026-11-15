import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';
import '../../core/story.dart';
import '../../core/voice.dart';

/// 晚安故事 (docs/design.md): tonight's story, a few big lines a page under
/// a small silhouette picture. The app reads it slowly and turns the page
/// by itself; a parent who turned reading off reads it aloud instead, the
/// words are their prompt.
class StoryView extends ConsumerStatefulWidget {
  const StoryView({super.key, required this.onDone, this.onBusy});

  final VoidCallback onDone;

  /// True while the app is reading or about to turn the page by itself
  /// (the evening does not count that as nobody touching), false once the
  /// last page has been read.
  final void Function(bool busy)? onBusy;

  /// After a page is read, the next one comes this much later.
  static const pause = Duration(milliseconds: 2500);

  @override
  ConsumerState<StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends ConsumerState<StoryView> {
  late final Sounds _sounds = ref.read(soundsProvider);
  late final Voice _voice = ref.read(voiceProvider);
  late final Story _story;
  late final List<StoryPage> _pages;
  late final bool _reads = ref.read(gameProvider).settings.readStory && ref.read(gameProvider).settings.voice;
  var _page = 0;
  var _turn = 0;
  var _done = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    final game = ref.read(gameProvider);
    _story = game.storyFor(now);
    _pages = _story.pages(game.settings.level);
    _sounds.hold(this, Music.wind, level: 0.4);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(gameProvider.notifier).change((g) => g.toldStory(_story, now));
      _show();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _turn++;
    _voice.stop();
    _sounds.release(this);
    super.dispose();
  }

  /// A page is on screen: read it (if the app reads), then turn.
  void _show() {
    final turn = ++_turn;
    _timer?.cancel();
    if (!_reads) return;
    widget.onBusy?.call(true);
    _timer = Timer(const Duration(milliseconds: 1200), () async {
      if (!mounted || turn != _turn) return;
      await _voice.read(_pages[_page].lines);
      if (!mounted || turn != _turn) return;
      _timer = Timer(StoryView.pause, () {
        if (mounted && turn == _turn) _next();
      });
    });
  }

  void _readAgain() => _show();

  void _next() {
    if (_done) return;
    _voice.stop();
    if (_page >= _pages.length - 1) {
      _done = true;
      _turn++;
      _timer?.cancel();
      widget.onBusy?.call(false);
      _timer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) widget.onDone();
      });
      setState(() {});
      return;
    }
    _sounds.play('page');
    setState(() => _page++);
    _show();
  }

  @override
  Widget build(BuildContext context) {
    final p = _pages[_page];
    final last = _page == _pages.length - 1;
    return NightSky(
      key: const ValueKey('story'),
      stars: 0.5,
      child: SafeArea(
        child: LayoutBuilder(builder: (context, box) {
          final pw = (box.maxWidth - 40).clamp(0.0, box.maxHeight * 0.5 * 320 / 200);
          // As big as fits: the longest line of the page on one line.
          final longest = p.lines.fold<int>(1, (a, l) => l.length > a ? l.length : a);
          final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
          final text = ((box.maxWidth - 52) / longest / scale).clamp(16.0, 34.0);
          return Column(children: [
            const ScreenTitle(Strings.storyTitle),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              child: SizedBox(key: ValueKey(_page), width: pw, height: pw * 200 / 320, child: StoryPicture(page: p)),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < _pages.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: i == _page ? Night.warm : Night.cardEdge),
                ),
            ]),
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 1000),
                  child: Padding(
                    key: ValueKey('text-$_page'),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      for (final l in p.lines) Text(l, textAlign: TextAlign.center, style: TextStyle(fontSize: text, height: 1.55, color: Night.text)),
                    ]),
                  ),
                ),
              ),
            ),
            if (!_reads) const Padding(padding: EdgeInsets.only(bottom: 8), child: Text(Strings.parentReads, style: TextStyle(fontSize: 14, color: Night.faint))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_reads) ...[
                  SoftButton(label: Strings.readToMe, icon: ArtPath.ui('speak'), onTap: _readAgain),
                  const SizedBox(width: 16),
                ],
                SoftButton(label: last ? Strings.goodnight : Strings.nextPage, icon: last ? null : ArtPath.ui('next'), onTap: _done ? null : _next, selected: last),
              ]),
            ),
          ]);
        }),
      ),
    );
  }
}

/// A story page's picture: the place, the small thing, the animal.
class StoryPicture extends StatelessWidget {
  const StoryPicture({super.key, required this.page});

  final StoryPage page;

  /// Where the prop and the animal go in the 320 x 200 place (design/art/story.py).
  static const thing = Rect.fromLTWH(190, 10, 120, 180);
  static const animal = Rect.fromLTWH(70, 86, 92, 110);

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: LayoutBuilder(builder: (context, box) {
          final k = box.maxWidth / 320;
          Rect at(Rect r) => Rect.fromLTWH(r.left * k, r.top * k, r.width * k, r.height * k);
          final a = at(animal);
          return Stack(children: [
            Positioned.fill(child: Art(ArtPath.place(page.place.name), fit: BoxFit.fill)),
            if (page.thing != null) Positioned.fromRect(rect: at(thing), child: Art(ArtPath.thing(page.thing!.name), fit: BoxFit.fill)),
            Positioned.fromRect(
              rect: a,
              child: page.asleep
                  ? Art(ArtPath.animal(page.who, asleep: true), tokens: AnimalPaint.story, alignment: Alignment.bottomCenter)
                  : Drift(turn: 0.03, seconds: 4, child: Art(ArtPath.animal(page.who), tokens: AnimalPaint.story, alignment: Alignment.bottomCenter)),
            ),
            if (page.asleep) Positioned(left: a.right - a.width * 0.3, top: a.top + a.height * 0.05, child: Zz(size: a.width * 0.35)),
          ]);
        }),
      );
}
