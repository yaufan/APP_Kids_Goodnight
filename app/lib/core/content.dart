/// The names of things in 晚安小鎮 (docs/design.md).
library;

/// How long the evening is: 2～3 歲 short, 4～5 歲 a little longer.
enum Level {
  small('2～3 歲（短）'),
  big('4～5 歲（長一點）');

  const Level(this.zh);

  final String zh;

  /// Sheep to count (數到 5 / 數到 10).
  int get sheep => this == small ? 5 : 10;

  /// Breaths with the moon.
  int get breaths => this == small ? 3 : 5;

  /// Pages in the story.
  int get pages => this == small ? 2 : 5;

  /// The lights on the street that are lit tonight.
  List<Light> get lights => this == small ? Light.forSmall : Light.values;
}

/// The parts of an evening, always in this order unless a parent moves
/// them; the lullaby is always last (docs/design.md 「玩法」).
enum Segment {
  checklist('晚安清單', '刷牙、尿尿、喝水、抱抱'),
  lights('關燈巡邏', '幫小鎮的每一家關燈（一定有）'),
  sheep('數羊', '一隻一隻跳過柵欄'),
  story('晚安故事', '短短的故事，APP 慢慢念'),
  breath('呼吸小月亮', '按住月亮吸氣，放開吐氣'),
  lullaby('搖籃曲', '螢幕慢慢變黑，時間到自己關掉');

  const Segment(this.zh, this.note);

  final String zh;
  final String note;

  /// The parts a parent may turn off (關燈巡邏 is the heart of it).
  static const optional = [checklist, sheep, story, breath, lullaby];

  /// The parts a parent may put in another order (the lullaby stays last).
  static const movable = [checklist, lights, sheep, story, breath];
}

/// The four things done for real before the screen (晚安清單).
enum Check {
  teeth('刷牙'),
  potty('尿尿'),
  water('喝水'),
  hug('抱抱');

  const Check(this.zh);

  final String zh;
}

/// The animals of the town; the sheep only lives in the stories (and the
/// meadow).
enum Animal {
  cat('小貓'),
  rabbit('小兔子'),
  bear('小熊'),
  duck('小鴨'),
  pig('小豬'),
  owl('貓頭鷹'),
  dog('小狗'),
  sheep('小羊');

  const Animal(this.zh);

  final String zh;

  /// Its own yawn (design/sounds: `yawn_<animal>`).
  String get yawn => 'yawn_$name';
}

/// Everything lit on the street at dusk (docs/design.md 「關燈巡邏」): seven
/// windows with an animal, one window without, the breakfast shop's door,
/// the snack shop's red lantern, the convenience store's sign, the lamp.
enum Light {
  cat(Animal.cat),
  rabbit(Animal.rabbit),
  bear(Animal.bear),
  duck(Animal.duck),
  pig(Animal.pig),
  owl(Animal.owl),
  dog(Animal.dog),
  window(null),
  door(null),
  lantern(null),
  sign(null),
  lamp(null);

  const Light(this.animal);

  final Animal? animal;

  /// 2～3 歲: six lights.
  static const forSmall = [cat, rabbit, bear, dog, lantern, lamp];

  /// What is said when it goes dark.
  String get goodnight => switch (this) {
        window => '這扇窗也關燈了，晚安～',
        door => '早餐店關門了，晚安～',
        lantern => '紅燈籠熄了，晚安～',
        sign => '招牌的燈關了，晚安～',
        lamp => '路燈也休息了，晚安～',
        _ => '${animal!.zh}睡了，晚安～',
      };
}

/// The lullaby sounds (docs/design.md 「搖籃曲與白噪音」); the first four
/// are in the free version.
enum Lullaby {
  musicBox('音樂盒'),
  humming('哼歌'),
  rain('雨聲'),
  waves('海浪'),
  fan('風扇'),
  heartbeat('心跳');

  const Lullaby(this.zh);

  final String zh;

  static const free = [musicBox, humming, rain, waves];

  bool get isFree => free.contains(this);
}

/// 一 to 十, for counting sheep.
String zhNumber(int n) => const ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十'][n.clamp(0, 10)];

/// The breathing moon (docs/design.md 「呼吸小月亮」).
abstract final class Breath {
  static const inhale = Duration(seconds: 4);
  static const exhale = Duration(seconds: 6);

  /// A press shorter than this is a tap, not a breath.
  static const minHold = Duration(milliseconds: 1500);
}

/// Sheep take their time over the fence.
const sheepJump = Duration(seconds: 3);

/// The night an evening belongs to: an evening that goes past midnight is
/// still the same night (counted from five in the morning).
int nightNumber(DateTime t) {
  final d = t.subtract(const Duration(hours: 5));
  return DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
}

/// Daytime (the town is still at dusk, but the app says it is not bedtime).
bool isDaytime(DateTime t) => t.hour >= 7 && t.hour < 17;
