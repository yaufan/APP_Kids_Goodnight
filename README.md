# 晚安小鎮

給 **2～5 歲**的小朋友，在台灣，國語為主：睡前最後 5～8 分鐘的安靜 APP，目的是**帶往睡覺**，不是玩。獨立的 APP，不是小小生活家的一部分。

- 設計：[docs/design.md](docs/design.md)，草圖在 `docs/mockups/`。
- 和「畫畫小鎮」「字母寵物」「動物小餐廳」「小卡認天下」「想一想樂園」「眼尖尖大挑戰」「迷宮小冒險」「小小生活家」是兄弟 APP：同一個作者、同一套技術、不同畫風。
- 不連網、不定位、沒有廣告、沒有帳號。

## 下載（Android）
- 最新版：[Releases](https://github.com/yaufan/APP_Kids_Goodnight/releases/latest)，一般手機下載 `goodnight-town-版本-arm64.apk`。
- 用手機掃描 [docs/download-qr.png](docs/download-qr.png)。

## 目前進度
- 0.1.0（測試版）：晚安清單、關燈巡邏（黃昏的台灣小街，12 盞燈、7 隻動物）、數羊、晚安故事（六個固定的故事＋片段組合）、呼吸小月亮、搖籃曲六種聲音和計時、螢幕變黑和自己關掉、一小時內再開只有搖籃曲、家長模式、全部音效、APP 圖示。星光剪影風。版本紀錄在 [CHANGELOG.md](CHANGELOG.md)。

## 程式和素材在哪裡
- `app/`：Flutter 程式。`lib/core/` 是內容的名字（`content.dart`）、一晚的順序和時間（`evening.dart`）、故事的片段（`story.dart`）、設定和紀錄（`game.dart`）、小街的位置（`street_layout.dart`，由 `design/art/street.py` 產生）、聲音、語音、螢幕（`screen.dart`）；`lib/features/` 是每一段的畫面：`checklist/`、`lights/`、`sheep/`、`story/`、`breath/`、`lullaby/`（含最後的晚安和只要搖籃曲），`evening/` 把它們串起來，`parent/` 是家長關卡和家長模式。
- `design/art/`：用 Python 畫的圖（星光剪影風），說明在 [design/art/README.md](design/art/README.md)。
- `design/sounds/make_sounds.py`：合成全部的聲音，說明在 [design/sounds/README.md](design/sounds/README.md)。
- 測試：在 `app/` 裡 `flutter test`；完整流程 `flutter test test/flow_test.dart`，截圖在 `app/build/screenshots/`；示範影片見 `CLAUDE.md`。

## 授權
- 非商業使用授權：自己、家人使用，或學校、非營利團體的教學，都可以免費使用、修改、分享，要註明出處。
- 商業用途（販賣、收費、廣告、上架）要先取得作者書面同意。也不可以拿來訓練 AI。
- 細節見 [LICENSE](LICENSE)；別人做的部分（字型）見 [NOTICE.md](NOTICE.md)。
