import '../core/content.dart';

/// Everything the app says, in Traditional Chinese (Taiwan).
abstract final class Strings {
  static const appName = '晚安小鎮';

  // The checklist.
  static const checklistTitle = '晚安清單';
  static const checklistLine = '睡覺前的四件事，做好了就點一下';
  static String checkDone(Check c) => '${c.zh}，好了。';
  static const checklistAll = '都做好了，我們去幫大家關燈。';
  static const checklistNote = '不想點也沒關係，等一下會自己往下走。';

  // The lights.
  static const lightsTitle = '關燈巡邏';
  static const lightsStart = '天黑了，幫大家關燈吧。';
  static const notYet = '現在還不是睡覺時間喔。';
  static const lightsHint = '點一下亮著的窗戶和燈';
  static String lightsLeft(int n) => '還有 $n 盞燈亮著';
  static const lightsAll = '大家都睡了。';

  // Sheep.
  static const sheepTitle = '數羊';
  static const sheepStart = '數小羊囉。點一下，小羊就會跳過去。';
  static const sheepHint = '點一下，下一隻小羊才會跳';
  static String sheepCount(int n) => '第$n隻小羊，跳過去了';
  static const sheepAll = '小羊都睡了。';

  // The story.
  static const storyTitle = '晚安故事';
  static const readToMe = '念給我聽';
  static const nextPage = '下一頁';
  static const goodnight = '晚安';
  static const parentReads = '請爸爸媽媽念給你聽';

  // The moon.
  static const breathTitle = '呼吸小月亮';
  static const breathStart = '跟著小月亮，慢慢呼吸。';
  static const breatheIn = '吸氣……';
  static const breatheOut = '慢慢吐氣……';
  static const yourTurn = '換你了，按住小月亮。';
  static const breathHint = '按住小月亮，跟著一起吸氣；放開，慢慢吐氣';
  static const breathAll = '好舒服。晚安，小月亮。';

  // The lullaby.
  static const lullabyTitle = '搖籃曲';
  static const lullabyStart = '聽搖籃曲，閉上眼睛。';
  static const howLong = '多久以後關掉';
  static String minutes(int m) => '$m 分鐘';
  static String minutesLeft(int m) => '還剩 $m 分鐘';
  static const lullabyNote = '螢幕會慢慢變黑，\n手機蓋起來放旁邊就好，\n不要按電源鍵（聲音會停）。';
  static const lullabyFoot = '搖籃曲停了，APP 就自己關掉。';

  // The end.
  static const yourTurnToSleep = '換你去睡了，晚安。';
  static const sleepWell = '晚安';

  // The parent's corner.
  static const parent = '給爸爸媽媽';
  static const callParent = '請爸爸媽媽來';
  static const parentGateTitle = '家長確認';
  static String gateQuestion(String a, String b) => '$a 加 $b 等於多少？';
  static const gateRules = '用下面的數字回答。答錯三次要等一分鐘，再錯會等更久。';
  static const wrongAnswer = '不對喔，換一題。';
  static String gateWait(Duration d) {
    final s = (d.inMilliseconds / 1000).ceil();
    return s > 60 ? '請等 ${(s + 59) ~/ 60} 分鐘再試。' : '請等 $s 秒再試。';
  }
  static const backspace = '刪掉';
  static const cancel = '取消';
  static const back = '回去';

  // Parent mode.
  static const parentTitle = '家長模式';
  static const age = '年齡（長度）';
  static const ageNote = '2～3 歲：燈 6 盞、數到 5、故事兩頁、呼吸三次。4～5 歲：燈 12 盞、數到 10、故事五頁、呼吸五次。';
  static const evening = '每次最多幾分鐘（整個 APP）';
  static const eveningNote = '從打開算起，搖籃曲不算在內。時間到了不管在哪一段，都溫柔地接到搖籃曲。';
  static const parts = '今晚要做哪些（照順序）';
  static const partsNote = '關燈巡邏一定有；搖籃曲永遠在最後。按箭頭可以往前移。';
  static const moveUp = '往前';
  static const checklistFull = '晚安清單在完整版裡。';
  static const lullabySection = '搖籃曲';
  static const lullabyLength = '搖籃曲最多幾分鐘';
  static const lullabyOnly = '只要搖籃曲';
  static const lullabyOnlyNote = '打開 APP 直接是黑畫面和聲音，小朋友不用看螢幕。';
  static const fullOnly = '完整版';
  static const storySection = '念故事';
  static const readStory = 'APP 念故事給小朋友聽（國語）';
  static const readStoryNote = '關掉的話，字是給家長看的提詞，請您自己念（小兒科最推薦）。';
  static const slowVoice = '念慢一點';
  static const screenSound = '螢幕和聲音';
  static const dim = '螢幕再暗一點';
  static const dimNote = 'APP 自己在畫面上蓋一層半透明的黑，不用系統權限。';
  static const volume = '音量';
  static const effects = '音效';
  static const voice = '語音（說話、數數）';
  static const tonight = '今晚';
  static String lockedLine(int m) => '剛剛說過晚安了：$m 分鐘內再打開，只會有黑畫面和搖籃曲。';
  static const unlock = '解開，從頭開始今晚';
  static const restart = '從頭開始今晚';
  static const week = '最近七天';
  static const weekNone = '還沒有紀錄。';
  static String weekLine(int nights, double avg) => '用了 $nights 個晚上，平均 ${avg.toStringAsFixed(1)} 分鐘。';
  static String mostSkipped(Segment s) => '最常跳過：${s.zh}';
  static const fullVersion = '完整版';
  static const fullNote = '免費版：關燈巡邏、數羊、呼吸小月亮、四種聲音（音樂盒、哼歌、雨聲、海浪）、六個固定的故事。完整版：全部六種聲音、每晚組合出不一樣的故事、晚安清單。以後只在這裡購買，一次買斷，不訂閱。';
  static const fullSwitch = '完整版（測試期間先打開）';
  static const about = '關於';
  static const privacy = '不連網、不定位、沒有廣告、沒有帳號、不要任何權限。設定和最近幾晚的紀錄只存在這支手機裡。';
  static String version(String v) => '版本 $v';
}
