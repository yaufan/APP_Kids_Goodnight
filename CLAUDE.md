# 給 Claude 的專案規則（晚安小鎮）

這份是這個專案的「記憶」。每個在這個專案裡工作的 Claude 都要照著做。它是「畫畫小鎮」（https://github.com/yaufan/APP_Kids_Paint）、「字母寵物」（https://github.com/yaufan/APP_Kids_Paint_for_learning_writing）、「動物小餐廳」（https://github.com/yaufan/APP_Kids_Cook）、「小卡認天下」（https://github.com/yaufan/APP_Kids_Card_Game）、「想一想樂園」（https://github.com/yaufan/APP_Kids_Brainstorming）、「眼尖尖大挑戰」（https://github.com/yaufan/APP_Kids_FalseCharge）、「迷宮小冒險」（https://github.com/yaufan/APP_Kids_maze）和「小小生活家」（https://github.com/yaufan/APP_Kids_live_circ）的兄弟 APP，技術和流程照那邊（畫風不同），這裡寫這個專案自己的事。程式的架構最接近小小生活家（Python 畫 SVG、ParentPass），有疑問先看那邊怎麼做。

## 和使用者合作
- **一律用繁體中文回覆**，用白話說明，少用技術名詞；要用的話順便解釋。
- 使用者用手機上的 Claude App 看對話，**打不開 artifact 連結**。圖片、影片、聲音、QR code 都用傳檔案的方式（SendUserFile）給。
- 設計階段：每個想法都畫成草圖（`docs/mockups/`）傳給使用者看，再問。
- 之後每做完一版：給示範影片片段、手機截圖、下載 QR code（和畫畫小鎮一樣）。
- 有要使用者決定的事，列出選項和我的建議，再問。
- 不要開 pull request，除非使用者要求。用了網路搜尋，回覆最後附「Sources:」和連結。

## 這個 APP
- 給 **2～5 歲**的小朋友，在台灣，國語為主：睡前最後 5～8 分鐘的安靜 APP，目的是**帶往睡覺**，不是玩。獨立的 APP，不是小小生活家的一部分。
- 照順序一段接一段：晚安清單（預設開、家長可關）→ 關燈巡邏（台灣小街，幫每一家關燈，動物睡著）→ 數羊 → 晚安故事（固定片段組合，APP 慢速念，家長可關掉自己念）→ 呼吸小月亮 → 搖籃曲與白噪音（螢幕黑著但不睡，時間到 APP 自己關掉說「換你去睡了」）。
- 沒有分數、貼紙、獎勵；不做「早安」。唯一的結果是小鎮安靜了。
- 設計在 [docs/design.md](docs/design.md)，改設計時一起改它；草圖在 `docs/mockups/`。
- 畫風：**星光剪影風**，只做一種（深藍夜、沒有框線的紙剪影、只有暖黃窗燈和星月亮著）。要和兄弟 APP 的畫風**不一樣**。
- 每次多久由家長設定（預設 8 分鐘：5／8／10），關掉後一小時內再開只有黑畫面和搖籃曲。
- 免費版：關燈巡邏完整＋數羊＋呼吸小月亮＋四種聲音（音樂盒、哼歌、雨聲、海浪）＋六個固定故事；完整版：全部聲音、組合故事、晚安清單、更多小鎮。購買只在家長模式。
- 技術名稱：Flutter 專案 `goodnight_town`、applicationId `com.yaufan.goodnighttown`、APK `goodnight-town-版本-arm64.apk`、簽章環境變數 `GOODNIGHT_TOWN_KEYSTORE`。
- 資安：不接受別的 APP 傳來的頁面（`flutter_deeplinking_enabled` 關掉、`overridePlatformDefaultLocation`），家長模式只能從家長關卡進去（`ParentPass`），不要任何權限。
- 不連網、不定位、沒有廣告、沒有帳號。以後上架要收費：免費下載一部分，一次買斷完整版，購買只在家長模式（要過家長關卡）。
- 每個動作都要有音效，全部用程式合成。
- 授權：非商業使用（`LICENSE`），中英文版本；別人做的部分（字型）在 `NOTICE.md`。
- 名稱：晚安小鎮。GitHub：https://github.com/yaufan/APP_Kids_Goodnight

## GitHub Actions
- 工作流程（照小小生活家；第一次放上 main 前要先問）：
  - `app.yml`（App）：推到 `main` 而且改到 `app/**` 時跑分析、全部測試（含完整流程）、打包 APK，約 15～20 分鐘。
  - `release.yml`（Release）：推到 `main` 而且改到 `app/pubspec.yaml`、`CHANGELOG.md` 或它自己時，版本還沒發布過就打包三個 APK 放上 Releases，約 20 分鐘；版本沒變約 1 分鐘。
  - `cleanup.yml`：手動，刪舊的建置檔案，約 1 分鐘。
- 推工作分支（`claude/...`）不會啟動任何工作流程。
- 簽章：和畫畫小鎮用**同一把測試金鑰**（別名 `kidspaint`），Secrets 名稱一樣：`ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`，要放在這個專案的 Actions → Secrets → Repository secrets。指紋 `TEST_KEY_SHA256` 寫在工作流程裡。以後上架要換成正式的上傳金鑰。
- 發新版本：`app/pubspec.yaml` 的 `version`、`app/lib/app/version.dart` 的預設值、`CHANGELOG.md` 最上面一段（`## 版本 …`）三個要一致（`test/version_test.dart` 檢查）。
- **任何會啟動 Actions 的動作，都要先問使用者，等使用者同意才做**，問的時候說清楚四件事：
  1. 會跑哪些工作流程。
  2. 這次大約用掉幾分鐘。
  3. 這個月目前用了多少。
  4. 跑完大約還剩多少。

  規則和畫畫小鎮的 `CLAUDE.md` 一樣；那個帳號每月 2,000 分鐘是所有私有專案共用的，Mac 主機的 1 分鐘算 10 分鐘。

## Git
- **發布新版本、做成可以安裝的 APK、給下載 QR code**：照 skill `release-kids-app`（`.claude/skills/release-kids-app/SKILL.md`），兄弟 APP 共用同一份。
- 在系統指定的 `claude/...` 工作分支上開發，commit 完就推這個分支。
- commit 訊息用英文寫清楚改了什麼和為什麼，結尾加系統要求的署名行。不要寫模型名稱。
- 不能 commit：金鑰、密碼、不公開的文件、`__pycache__`。

## 和畫畫小鎮共用的做法（開始寫程式時照著做）
- Flutter 3.47.8、Riverpod、flutter_svg、audioplayers、flutter_tts。存檔是一個 JSON 檔（`app/lib/core/store.dart`），沒有用 drift，所以本機跑測試**不用** sqlite 那段，直接 `flutter test`。
- 觸控：用原始的手指事件（`Listener`），手指一碰就畫。不要用拖曳手勢，它要移動 36 點才開始，小朋友短短的一筆會不見。
- 圖和聲音都用程式產生（SVG 用 Python 畫；聲音用 numpy 合成），不用別人的素材。
- 本機測試：在 `app/` 裡 `flutter test`（不含 `test/flow_test.dart`），`flutter analyze` 要零問題。以後加了 drift，才照畫畫小鎮的 `tools/run_tests.sh`（pubspec 的 sqlite 那段不能 commit）。
- 完整流程和截圖：`flutter test test/flow_test.dart`，截圖在 `app/build/screenshots/`。
- 示範影片（每一版都要給使用者）：在 `app/` 裡 `flutter test test/demo/demo_video_test.dart --dart-define=DEMO=true`（約 5～10 分鐘，要 ffmpeg），再在專案根目錄 `python3 tools/demo_audio.py` 把背景音樂和音效混進去。輸出 `app/build/demo/demo.mp4`；`chapters.txt` 是每一段開始的格數（每秒 10 格），用來剪新功能的片段。

## 程式在哪裡
- `app/lib/core/`：內容的名字（`content.dart`：段落、晚安清單、動物、燈、搖籃曲、年齡的數量）、一晚的順序和計時（`evening.dart`：哪些段落、多久沒碰就往下、家長的分鐘到了接搖籃曲、搖籃曲的時鐘和最後兩分鐘變小聲）、故事的片段和組合（`story.dart`）、設定和紀錄（`game.dart`：一小時的鎖、最近七天、上次的故事）、小街的位置（`street_layout.dart`，`design/art/street.py` 產生，不要手改）、聲音（`sounds.dart`）、語音（`voice.dart`，國語慢速、句子之間停一下）、螢幕（`screen.dart`：保持開著、APP 視窗變暗、自己關掉）、存檔。
- `app/lib/features/`：`evening/`（一段接一段、慢慢淡入淡出、多久沒碰和時間到）、`checklist/`、`lights/`（小街、窗戶裡的動物）、`sheep/`、`story/`、`breath/`、`lullaby/`（搖籃曲、最後的「換你去睡了」、只要搖籃曲的黑畫面）、`ended/`（關掉以後；iOS 停在這裡）、`parent/`（家長關卡、家長模式）。
- 螢幕黑著但不睡：`app/android/.../MainActivity.kt` 和 `app/ios/Runner/AppDelegate.swift` 的 `goodnight_town/screen` 通道（視窗旗標，不要權限）。
- 圖：`design/art/`（Python 畫 SVG：`kit.py` 畫法和檢查、`street.py` 小街和每一盞燈、`animals.py`、`sky.py`、`sheep.py`、`story.py`、`icons.py`、`icon.py` APP 圖示；`python3 build.py all` 全部重畫和檢查，`street OUT.png` 預覽小街，`fluttercheck` 用真的 flutter_svg 比對；說明在 `design/art/README.md`）。聲音：`design/sounds/make_sounds.py`（說明在 `README.md`）。
- 測試：`rules_test`（規則）、`evening_test`（畫面上的規則）、`art_test`、`safety_test`、`version_test`、`flow_test`（手機 2～3 歲、平板 4～5 歲各走一晚，截圖）、`demo/demo_video_test`。

## 目前的狀態（2026-11-15）
- 0.1.0 做好、測試都過了；GitHub 專案建好了，工作分支 `claude/relaxed-albattani-6mbwpz` 已推上去（GitHub 的 main 只有建專案時自動加的檔案，已經合併進工作分支，所以之後 main 可以直接快轉）。推 main 前要先問，Secrets 要先加。
- 還沒在真手機上試過：螢幕黑著時會不會睡、Android 自己關掉、窗戶的亮度、聲音的大小和慢速語音，都要用手機確認。
