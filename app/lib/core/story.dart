import 'dart:math' as math;

import 'content.dart';

/// The goodnight story (docs/design.md 「晚安故事」): put together from fixed
/// pieces written by a person — who × where × a small thing × a quiet
/// ending — never made up on the spot. Every combination reads as one
/// gentle story; `{who}` is the animal's name.
///
/// 2～3 歲: two pages (where and the small thing; the ending).
/// 4～5 歲: five pages (where; the small thing; what came of it; the ending;
/// 晚安).

/// Where it happens; the picture is `story/place_<name>.svg`.
enum Place {
  roof(
    ['天黑了，小鎮靜悄悄的。', '{who}爬到屋頂上，', '坐在涼涼的瓦片旁邊，', '看著天上的月亮。'],
    ['天黑了，{who}坐在屋頂上，', '看著天上的月亮。'],
  ),
  shop(
    ['早餐店關門了，', '{who}躲在桌子下面，', '聞到一點點饅頭的香味，', '眼睛慢慢地眨呀眨。'],
    ['早餐店關門了，', '{who}躲在桌子下面。'],
  ),
  park(
    ['公園裡沒有人了，', '{who}走到大樹下，', '聽樹葉沙沙地說話，', '風輕輕地吹過來。'],
    ['{who}走到公園的大樹下，', '樹葉沙沙地響。'],
  ),
  temple(
    ['廟口的燈籠暗暗的，', '{who}坐在石獅子旁邊，', '石獅子也在打瞌睡，', '嘴巴張得圓圓的。'],
    ['{who}坐在廟口的石獅子旁邊，', '石獅子也在打瞌睡。'],
  ),
  beach(
    ['海邊的沙子涼涼的，', '{who}坐在沙灘上，', '海浪一下一下地來，', '嘩……嘩……'],
    ['{who}坐在海邊的沙灘上，', '海浪嘩……嘩……'],
  ),
  hill(
    ['小鎮後面有一座小山，', '{who}慢慢走到山頂上，', '低頭一看，', '小鎮的燈一盞一盞關掉了。'],
    ['{who}走到小山上，', '小鎮的燈一盞一盞關掉了。'],
  );

  const Place(this.long, this.short);

  final List<String> long;
  final List<String> short;
}

/// The small thing that happens; its picture is `story/thing_<name>.svg`.
enum Happening {
  star(
    ['咚！有一顆小星星，', '從天上掉下來了，', '剛好掉在{who}的旁邊。'],
    ['小星星亮亮的、暖暖的，', '{who}把它抱在懷裡，', '輕輕地說：「我送你回家。」', '小星星飛回天上，眨了眨眼睛。'],
    ['一顆小星星掉下來，', '{who}輕輕把它送回天上。'],
  ),
  pillow(
    ['{who}想睡覺了，', '可是，枕頭不見了。', '「我的枕頭在哪裡呢？」'],
    ['{who}慢慢地找，', '找到了！', '枕頭在月光下面，', '被月亮照得暖暖的、軟軟的。'],
    ['{who}的枕頭不見了，', '原來在月光下面，暖暖的。'],
  ),
  wind(
    ['呼……呼……', '{who}聽到風在唱歌，', '唱得好小聲、好小聲。'],
    ['風說：「噓，大家都要睡了。」', '{who}也跟著小聲地哼，', '嗯……嗯……'],
    ['風輕輕地唱歌，', '{who}也小聲地跟著哼。'],
  ),
  moonHides(
    ['咦？月亮不見了。', '原來月亮躲到雲後面，', '想要睡一下。'],
    ['{who}輕輕地說：', '「月亮，晚安。」', '雲朵慢慢飄開，', '月亮笑一笑，又出來了。'],
    ['月亮躲到雲後面，', '{who}說：「月亮，晚安。」'],
  ),
  rain(
    ['滴答、滴答，', '下了一陣小小的雨，', '{who}躲到大葉子下面。'],
    ['雨聲滴答滴答，', '好像在說：「睡吧，睡吧。」', '雨停了，', '空氣涼涼的、香香的。'],
    ['滴答滴答，下小雨了，', '雨聲好像在說：「睡吧。」'],
  ),
  friend(
    ['沙、沙、沙，', '有人輕輕地走過來，', '原來是好朋友小刺蝟。'],
    ['小刺蝟說：', '「我來跟你說晚安。」', '{who}笑了，', '「晚安，明天見。」'],
    ['好朋友小刺蝟走過來，', '說：「晚安，明天見。」'],
  ),
  firefly(
    ['一隻小螢火蟲飛過來，', '尾巴亮亮的，', '像一盞小小的燈。'],
    ['螢火蟲說：「我也要關燈了。」', '牠的燈慢慢、慢慢地暗下來，', '{who}說：「晚安，螢火蟲。」'],
    ['一隻小螢火蟲飛過來，', '慢慢把小燈關掉了。'],
  ),
  leaf(
    ['一片大大的葉子，', '從樹上飄下來，', '飄呀飄，飄到{who}身上。'],
    ['葉子好像一條小被子，', '{who}把它拉高一點，', '暖暖的，好舒服。'],
    ['一片大葉子飄下來，', '像小被子蓋在{who}身上。'],
  ),
  countStars(
    ['天上有好多星星，', '{who}一顆一顆地數，', '一、二、三……'],
    ['數著數著，', '眼睛越來越重，', '{who}打了一個大哈欠，', '哈～～'],
    ['{who}數星星，', '一、二、三……眼睛越來越重。'],
  ),
  callHome(
    ['遠遠的，', '傳來媽媽的聲音：', '「寶貝，該回家睡覺囉。」'],
    ['{who}說：「好，我來了。」', '慢慢地、慢慢地，', '走回暖暖的家。'],
    ['遠遠傳來媽媽的聲音：', '「寶貝，該睡覺囉。」'],
  );

  const Happening(this.first, this.then, this.short);

  final List<String> first;
  final List<String> then;
  final List<String> short;
}

/// The quiet ending.
enum Ending {
  yawnHome(
    ['{who}打了一個大哈欠，', '慢慢走回家，', '鑽進暖暖的被子裡，', '閉上眼睛。'],
    ['{who}打了一個哈欠，', '回家睡覺了。'],
  ),
  pillowHug(
    ['{who}抱著軟軟的小枕頭，', '縮成圓圓的一團，', '呼吸慢慢的、輕輕的，', '睡著了。'],
    ['{who}抱著小枕頭，', '慢慢睡著了。'],
  ),
  moonSings(
    ['月亮輕輕地唱歌，', '唱給{who}聽，', '嗯……嗯……', '{who}的眼睛閉起來了。'],
    ['月亮唱歌給{who}聽，', '{who}的眼睛閉起來了。'],
  ),
  starBlanket(
    ['星星們排成一條小被子，', '輕輕地蓋在{who}身上，', '亮亮的、暖暖的，', '{who}睡著了。'],
    ['星星輕輕地蓋在{who}身上，', '{who}睡著了。'],
  );

  const Ending(this.long, this.short);

  final List<String> long;
  final List<String> short;
}

/// One page: the lines, and what its picture shows.
class StoryPage {
  const StoryPage(this.lines, {required this.place, required this.who, this.thing, this.asleep = false});

  final List<String> lines;
  final Place place;
  final Animal who;
  final Happening? thing;
  final bool asleep;

  String get text => lines.join();
}

/// A story: who, where, what happened and how it ends.
class Story {
  const Story(this.who, this.place, this.thing, this.ending);

  final Animal who;
  final Place place;
  final Happening thing;
  final Ending ending;

  /// A short name, kept to avoid telling the same story two nights running.
  String get key => '${who.name}.${place.name}.${thing.name}.${ending.name}';

  static Story? fromKey(String? key) {
    final p = key?.split('.');
    if (p == null || p.length != 4) return null;
    final w = Animal.values.asNameMap()[p[0]], pl = Place.values.asNameMap()[p[1]], t = Happening.values.asNameMap()[p[2]], e = Ending.values.asNameMap()[p[3]];
    if (w == null || pl == null || t == null || e == null) return null;
    return Story(w, pl, t, e);
  }

  @override
  bool operator ==(Object other) => other is Story && other.key == key;

  @override
  int get hashCode => key.hashCode;

  /// Pieces that do not go together (the same thing said twice).
  static bool fits(Happening t, Ending e) => !((t == Happening.callHome || t == Happening.countStars) && e == Ending.yawnHome);

  /// Every story the pieces make.
  static final all = [
    for (final w in Animal.values)
      for (final p in Place.values)
        for (final t in Happening.values)
          for (final e in Ending.values)
            if (fits(t, e)) Story(w, p, t, e),
  ];

  /// The free version's six stories (docs/design.md 「免費版」).
  static const fixed = [
    Story(Animal.cat, Place.roof, Happening.star, Ending.starBlanket),
    Story(Animal.rabbit, Place.park, Happening.wind, Ending.moonSings),
    Story(Animal.bear, Place.hill, Happening.countStars, Ending.pillowHug),
    Story(Animal.duck, Place.beach, Happening.firefly, Ending.yawnHome),
    Story(Animal.dog, Place.shop, Happening.callHome, Ending.pillowHug),
    Story(Animal.owl, Place.temple, Happening.moonHides, Ending.starBlanket),
  ];

  /// Tonight's story: the same all evening ([night] from [nightNumber]),
  /// never the one told the night before ([last]). The full version puts
  /// one together from the pieces; the free one takes the six in turn.
  static Story tonight(int night, {required bool full, Story? last}) {
    if (!full) {
      var i = night % fixed.length;
      if (fixed[i] == last) i = (i + 1) % fixed.length;
      return fixed[i];
    }
    final r = math.Random(night * 7919 + 17);
    var s = all[r.nextInt(all.length)];
    // A different animal from last night's, so it feels new but calm.
    while (last != null && (s.who == last.who || s == last)) {
      s = all[r.nextInt(all.length)];
    }
    return s;
  }

  /// The pages for a child of [level].
  List<StoryPage> pages(Level level) {
    List<String> fill(List<String> lines) => [for (final l in lines) l.replaceAll('{who}', who.zh)];
    if (level == Level.small) {
      return [
        StoryPage(fill([...place.short, ...thing.short]), place: place, who: who, thing: thing),
        StoryPage(fill([...ending.short, '晚安，{who}。晚安，你。']), place: place, who: who, asleep: true),
      ];
    }
    return [
      StoryPage(fill(place.long), place: place, who: who),
      StoryPage(fill(thing.first), place: place, who: who, thing: thing),
      StoryPage(fill(thing.then), place: place, who: who, thing: thing),
      StoryPage(fill(ending.long), place: place, who: who, asleep: true),
      StoryPage(fill(['晚安，{who}。', '晚安，小鎮。', '晚安，你。']), place: place, who: who, asleep: true),
    ];
  }

  /// About how long reading it aloud slowly takes: the slow voice says
  /// about three characters a second, with a second's pause after every
  /// line and a few seconds for each page to turn.
  static Duration readingTime(List<StoryPage> pages) {
    var ms = 0;
    for (final p in pages) {
      for (final l in p.lines) {
        ms += l.length * 330 + 1000;
      }
      ms += 3000;
    }
    return Duration(milliseconds: ms);
  }

  /// The longest a story may be (docs/design.md: 2～3 歲 about 1.5 minutes,
  /// 4～5 歲 3～4 minutes).
  static Duration longest(Level level) => level == Level.small ? const Duration(seconds: 90) : const Duration(minutes: 4);
}
