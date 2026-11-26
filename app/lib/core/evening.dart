import 'content.dart';
import 'game.dart';

/// Tonight's parts in order (docs/design.md 「玩法」): the parent's order,
/// without the parts turned off, the lullaby last. 關燈巡邏 is always there;
/// 晚安清單 is in the full version only. 「只要搖籃曲」 is the lullaby alone.
List<Segment> eveningPlan(Settings s) {
  if (s.lullabyOnly) return const [Segment.lullaby];
  return [
    for (final seg in s.order)
      if (seg == Segment.lights || (!s.off.contains(seg) && (seg != Segment.checklist || s.full))) seg,
    if (!s.off.contains(Segment.lullaby)) Segment.lullaby,
  ];
}

/// An evening under way: which part is on, when it started, what was
/// passed by. After the last part comes the good night (「換你去睡了」).
class Evening {
  const Evening({required this.plan, required this.started, this.index = 0, this.skipped = const [], this.run = 0});

  factory Evening.start(Settings s, DateTime now, {int run = 0}) => Evening(plan: eveningPlan(s), started: now, run: run);

  final List<Segment> plan;

  /// When it began, less any time spent in parent mode ([shifted]).
  final DateTime started;
  final int index;
  final List<Segment> skipped;

  /// Which evening since the app opened (a parent's 重新開始 begins the next
  /// one, so every part starts afresh).
  final int run;

  /// The same evening with [away] (parent mode, the background) not
  /// counted; a negative [away] is a clock moved back, which gives no extra
  /// time.
  Evening shifted(Duration away) => Evening(plan: plan, started: started.add(away), index: index, skipped: skipped, run: run);

  /// The parent changed tonight's parts (parent mode, 「今晚要做哪些」): the
  /// parts already done stay, the rest follow [next] (a part turned off goes,
  /// 「只要搖籃曲」 goes straight to the lullaby). The part on screen goes on
  /// if it is still next. Once good night is said nothing changes.
  Evening replanned(List<Segment> next) {
    if (saidGoodnight) return this;
    final done = plan.sublist(0, index);
    return Evening(plan: [...done, ...next.where((s) => !done.contains(s))], started: started, index: index, skipped: skipped, run: run);
  }

  /// Whether [next] would change the parts still to come.
  bool differs(List<Segment> next) {
    final done = plan.sublist(0, index);
    final rest = next.where((s) => !done.contains(s)).toList();
    final now = plan.sublist(index);
    if (rest.length != now.length) return true;
    for (var i = 0; i < rest.length; i++) {
      if (rest[i] != now[i]) return true;
    }
    return false;
  }

  /// Null once every part is over (the good night).
  Segment? get current => index < plan.length ? plan[index] : null;

  bool get over => index >= plan.length;

  /// The lullaby has begun (or there is none and the evening is over).
  bool get saidGoodnight => current == Segment.lullaby || over;

  /// The part is done (or, with [passedBy], nobody touched it for a long
  /// time) and the next one begins.
  Evening next({bool passedBy = false}) {
    final c = current;
    if (c == null) return this;
    return Evening(plan: plan, started: started, index: index + 1, skipped: passedBy ? [...skipped, c] : skipped, run: run);
  }

  /// The parent's minutes are up: whatever is on, the lullaby comes (or the
  /// good night, without one). The parts not reached count as passed by.
  Evening timeUp() {
    if (saidGoodnight) return this;
    final lullaby = plan.indexOf(Segment.lullaby);
    final to = lullaby < 0 ? plan.length : lullaby;
    return Evening(plan: plan, started: started, index: to, skipped: [...skipped, ...plan.sublist(index, to)], run: run);
  }

  /// The evening (not counting the lullaby) has gone on as long as the
  /// parent allowed.
  bool overTime(DateTime now, Settings s) => !saidGoodnight && now.difference(started) >= Duration(minutes: s.minutes);

  /// How long a part waits for a touch before it quietly moves on (the
  /// checklist a minute, docs/design.md; the lullaby never). The wait starts
  /// again after the app has finished doing something (reading the story:
  /// a part that is busy never times out).
  static Duration? idleLimit(Segment s, Settings settings) => switch (s) {
        Segment.checklist => const Duration(seconds: 60),
        Segment.lights || Segment.sheep => const Duration(seconds: 90),
        Segment.story => settings.readStory ? const Duration(seconds: 90) : const Duration(minutes: 3),
        Segment.breath => const Duration(seconds: 45),
        Segment.lullaby => null,
      };
}

/// The lullaby's clock (docs/design.md 「搖籃曲與白噪音」): the sound plays
/// for the minutes chosen, gets quieter over the last two, and then the
/// app closes itself.
class LullabyClock {
  const LullabyClock(this.started, this.minutes);

  final DateTime started;
  final int minutes;

  static const fadeOut = Duration(minutes: 2);

  Duration get length => Duration(minutes: minutes);

  Duration remaining(DateTime now) {
    final r = length - now.difference(started);
    return r.isNegative ? Duration.zero : r;
  }

  /// Minutes left as shown (「還剩 18 分鐘」): rounded up.
  int minutesLeft(DateTime now) => (remaining(now).inSeconds / 60).ceil();

  bool done(DateTime now) => remaining(now) == Duration.zero;

  /// 1 until the last two minutes, then down to 0.
  double volume(DateTime now) {
    final r = remaining(now);
    if (r >= fadeOut) return 1;
    return r.inMilliseconds / fadeOut.inMilliseconds;
  }
}
