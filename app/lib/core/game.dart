import 'dart:math' as math;

import 'content.dart';
import 'story.dart';

/// What a parent set (parent mode, docs/design.md 「家長模式」).
class Settings {
  const Settings({
    this.level = Level.small,
    this.minutes = 8,
    this.off = const {},
    this.order = Segment.movable,
    this.lullaby = Lullaby.musicBox,
    this.lullabyMinutes = 20,
    this.lullabyOnly = false,
    this.readStory = true,
    this.slowVoice = true,
    this.dim = 0.0,
    this.volume = 0.7,
    this.sounds = true,
    this.voice = true,
    this.full = true,
  });

  final Level level;

  /// The whole evening before the lullaby (5 / 8 / 10 minutes).
  final int minutes;

  /// Parts turned off tonight (晚安清單, 數羊…; never 關燈巡邏).
  final Set<Segment> off;

  /// The order of the parts before the lullaby.
  final List<Segment> order;

  final Lullaby lullaby;

  /// How long the lullaby plays before the app closes itself.
  final int lullabyMinutes;

  /// Straight to the black screen and the lullaby.
  final bool lullabyOnly;

  /// The app reads the story aloud (off: the words are for the parent).
  final bool readStory;

  /// The voice reads slowly (about 0.7 of normal).
  final bool slowVoice;

  /// How much darker the app makes its own pictures (a black layer; no
  /// system permission): 0 to [maxDim].
  final double dim;

  /// All the app's sounds together, 0.2 to 1.
  final double volume;

  /// Little sound effects.
  final bool sounds;

  /// The voice (lines, counting).
  final bool voice;

  /// The full version (everything); on while testing.
  final bool full;

  static const minuteChoices = [5, 8, 10];
  static const lullabyChoices = [10, 20, 30];
  static const maxDim = 0.6;

  /// The lullaby sound actually used (a free phone falls back to the music box).
  Lullaby get sound => full || lullaby.isFree ? lullaby : Lullaby.musicBox;

  Settings copyWith({
    Level? level,
    int? minutes,
    Set<Segment>? off,
    List<Segment>? order,
    Lullaby? lullaby,
    int? lullabyMinutes,
    bool? lullabyOnly,
    bool? readStory,
    bool? slowVoice,
    double? dim,
    double? volume,
    bool? sounds,
    bool? voice,
    bool? full,
  }) =>
      Settings(
        level: level ?? this.level,
        minutes: minutes ?? this.minutes,
        off: off ?? this.off,
        order: order ?? this.order,
        lullaby: lullaby ?? this.lullaby,
        lullabyMinutes: lullabyMinutes ?? this.lullabyMinutes,
        lullabyOnly: lullabyOnly ?? this.lullabyOnly,
        readStory: readStory ?? this.readStory,
        slowVoice: slowVoice ?? this.slowVoice,
        dim: dim ?? this.dim,
        volume: volume ?? this.volume,
        sounds: sounds ?? this.sounds,
        voice: voice ?? this.voice,
        full: full ?? this.full,
      );

  /// Moves [s] one place earlier in the order.
  Settings moveUp(Segment s) {
    final o = [...order];
    final i = o.indexOf(s);
    if (i <= 0) return this;
    o[i] = o[i - 1];
    o[i - 1] = s;
    return copyWith(order: o);
  }

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'minutes': minutes,
        'off': [for (final s in off) s.name],
        'order': [for (final s in order) s.name],
        'lullaby': lullaby.name,
        'lullabyMinutes': lullabyMinutes,
        'lullabyOnly': lullabyOnly,
        'readStory': readStory,
        'slowVoice': slowVoice,
        'dim': dim,
        'volume': volume,
        'sounds': sounds,
        'voice': voice,
        'full': full,
      };

  factory Settings.fromJson(Map<String, dynamic> j) {
    bool flag(String k, bool d) => j[k] is bool ? j[k] as bool : d;
    double number(String k, double d, double lo, double hi) => j[k] is num ? (j[k] as num).toDouble().clamp(lo, hi) : d;
    final m = j['minutes'], lm = j['lullabyMinutes'], off = j['off'], order = j['order'];
    final ordered = <Segment>[
      if (order is List)
        for (final n in order)
          if (Segment.values.asNameMap()[n] case final s? when Segment.movable.contains(s)) s,
    ];
    // Every movable part exactly once, whatever the file says.
    final fixedOrder = [...ordered.toSet(), ...Segment.movable.where((s) => !ordered.contains(s))];
    return Settings(
      level: Level.values.asNameMap()[j['level']] ?? Level.small,
      minutes: m is int && minuteChoices.contains(m) ? m : 8,
      off: {
        if (off is List)
          for (final n in off)
            if (Segment.values.asNameMap()[n] case final s? when Segment.optional.contains(s)) s,
      },
      order: fixedOrder,
      lullaby: Lullaby.values.asNameMap()[j['lullaby']] ?? Lullaby.musicBox,
      lullabyMinutes: lm is int && lullabyChoices.contains(lm) ? lm : 20,
      lullabyOnly: flag('lullabyOnly', false),
      readStory: flag('readStory', true),
      slowVoice: flag('slowVoice', true),
      dim: number('dim', 0, 0, maxDim),
      volume: number('volume', 0.7, 0.2, 1),
      sounds: flag('sounds', true),
      voice: flag('voice', true),
      full: flag('full', true),
    );
  }
}

/// One evening, for the parent's page (the last seven days are shown).
class NightRecord {
  const NightRecord({required this.night, required this.seconds, this.skipped = const []});

  /// [nightNumber] of the evening.
  final int night;

  /// From opening the app to the lullaby.
  final int seconds;

  /// Parts that were passed by (nobody touched them, or the time ran out).
  final List<Segment> skipped;

  Map<String, dynamic> toJson() => {'night': night, 'seconds': seconds, 'skipped': [for (final s in skipped) s.name]};

  static NightRecord? fromJson(dynamic j) {
    if (j is! Map) return null;
    final n = j['night'], s = j['seconds'], sk = j['skipped'];
    if (n is! int || s is! int || s < 0) return null;
    return NightRecord(night: n, seconds: s, skipped: [
      if (sk is List)
        for (final x in sk) ?Segment.values.asNameMap()[x],
    ]);
  }
}

/// The last seven days at a glance.
class Week {
  const Week(this.nights, this.averageMinutes, this.mostSkipped);

  final int nights;
  final double averageMinutes;
  final Segment? mostSkipped;
}

/// Everything kept on the phone: the settings, when good night was said,
/// the last story, the last evenings. One small file (store.dart).
class Game {
  const Game({this.settings = const Settings(), this.goodnightAt, this.lastStory, this.lastStoryNight, this.history = const []});

  final Settings settings;

  /// When the evening reached the lullaby (the app opens on the black
  /// screen and the lullaby for an hour after it).
  final DateTime? goodnightAt;

  /// The story told last, and on which night.
  final String? lastStory;
  final int? lastStoryNight;
  final List<NightRecord> history;

  static const lockLength = Duration(hours: 1);
  static const historyKept = 14;

  /// Good night was said less than an hour ago.
  bool locked(DateTime now) {
    final at = goodnightAt;
    if (at == null) return false;
    final d = now.difference(at);
    return !d.isNegative && d < lockLength;
  }

  Game copyWith({Settings? settings, DateTime? goodnightAt, bool unlock = false, String? lastStory, int? lastStoryNight, List<NightRecord>? history}) => Game(
        settings: settings ?? this.settings,
        goodnightAt: unlock ? null : (goodnightAt ?? this.goodnightAt),
        lastStory: lastStory ?? this.lastStory,
        lastStoryNight: lastStoryNight ?? this.lastStoryNight,
        history: history ?? this.history,
      );

  /// Tonight's story: the one already chosen tonight, or a new one that is
  /// not last night's.
  Story storyFor(DateTime now) {
    final night = nightNumber(now);
    final last = Story.fromKey(lastStory);
    if (last != null && lastStoryNight == night && (settings.full || Story.fixed.contains(last))) return last;
    return Story.tonight(night, full: settings.full, last: last);
  }

  /// Remembers tonight's story.
  Game toldStory(Story s, DateTime now) => copyWith(lastStory: s.key, lastStoryNight: nightNumber(now));

  /// The evening reached the lullaby: good night is said, the evening kept
  /// for the parent's page (one record a night, the latest wins).
  Game sayGoodnight(DateTime now, {required Duration used, List<Segment> skipped = const []}) {
    final night = nightNumber(now);
    final record = NightRecord(night: night, seconds: used.inSeconds, skipped: skipped);
    final kept = [for (final r in history) if (r.night != night) r, record];
    return copyWith(goodnightAt: now, history: kept.skip(math.max(0, kept.length - historyKept)).toList());
  }

  /// The last seven days (nights, average minutes, the part most often
  /// passed by).
  Week week(DateTime now) {
    final today = nightNumber(now);
    final recent = [for (final r in history) if (today - r.night >= 0 && today - r.night < 7) r];
    final counts = <Segment, int>{};
    for (final r in recent) {
      for (final s in r.skipped) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    Segment? most;
    for (final e in counts.entries) {
      if (most == null || e.value > counts[most]!) most = e.key;
    }
    final avg = recent.isEmpty ? 0.0 : recent.fold<int>(0, (a, r) => a + r.seconds) / recent.length / 60;
    return Week(recent.length, avg, most);
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'settings': settings.toJson(),
        if (goodnightAt != null) 'goodnightAt': goodnightAt!.toIso8601String(),
        if (lastStory != null) 'lastStory': lastStory,
        if (lastStoryNight != null) 'lastStoryNight': lastStoryNight,
        'history': [for (final r in history) r.toJson()],
      };

  factory Game.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const Game();
    final at = j['goodnightAt'], ls = j['lastStory'], ln = j['lastStoryNight'], h = j['history'];
    return Game(
      settings: Settings.fromJson(j['settings'] is Map ? (j['settings'] as Map).cast<String, dynamic>() : const {}),
      goodnightAt: at is String ? DateTime.tryParse(at) : null,
      lastStory: ls is String && Story.fromKey(ls) != null ? ls : null,
      lastStoryNight: ln is int ? ln : null,
      history: [
        if (h is List)
          for (final r in h) ?NightRecord.fromJson(r),
      ],
    );
  }
}
