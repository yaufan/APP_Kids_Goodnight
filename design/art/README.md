# 晚安小鎮的圖（星光剪影風）

全部的圖都是 Python 畫的 SVG（`app/assets/art/`），給 flutter_svg 畫。畫風：深藍色的夜、沒有框線的紙剪影，只有暖黃的窗燈、紅燈籠、路燈、星星和月亮會亮。

| 檔案 | 畫什麼 |
|---|---|
| `kit.py` | 畫筆：顏色、形狀（圓、圓角方塊、月牙、雲、星星）、光暈（一層一層半透明的圓）、檢查規則 |
| `street.py` | 小街（`street/street.svg`，窗戶全部是暗的）、每一盞燈亮著的樣子（`street/glow_<燈>.svg`）、鐵窗（`street/grille.svg`），也寫 `app/lib/core/street_layout.dart`（每一盞燈放在哪裡、點哪裡） |
| `animals.py` | 窗戶裡的動物，醒著和睡著（`animals/<動物>_awake.svg`、`_sleep.svg`）；顏色是 `#BODY`、`#EYE`、`#LID`，APP 換成要的顏色 |
| `sky.py` | 月牙（有睡臉）、呼吸的圓月亮、Zz |
| `sheep.py` | 數羊的草地和柵欄、小羊（跳和睡） |
| `story.py` | 故事的六個地方（`story/place_*.svg`）和十件小事的道具（`story/thing_*.svg`） |
| `icons.py` | 單色的圖示（APP 上色）：晚安清單、搖籃曲的六種聲音、按鈕 |
| `icon.py` | APP 圖示（Android 和 iOS） |
| `build.py` | 全部重畫和檢查、預覽、`fluttercheck` |

```
python3 build.py all                       # 全部重畫，再檢查
python3 build.py street OUT.png dark=cat,rabbit   # 小街照 APP 的樣子組起來（虛線是點的範圍，紅框是手機一定看得到的地方）
python3 build.py story OUT.png             # 故事的圖
python3 build.py sheet OUT.png [資料夾]     # 全部的圖排成一張
python3 build.py fluttercheck              # 用真的 flutter_svg 和 Chromium 各畫一次，比對
python3 icon.py preview OUT.png            # APP 圖示預覽（和兄弟 APP 放在一起）
python3 icon.py export                     # 寫進 Android 和 iOS
```

規則（`kit.check_svg` 和 `app/test/art_test.dart` 都會檢查）：不能用 `<filter>`、`<mask>`、`<style>`、`<text>`、`<image>`、`<pattern>`、`<clipPath>`、`<use>`；每個檔案小於 70 KB；光暈用疊起來的半透明圓。

加一盞燈：在 `street.py` 的 `WINDOWS`（或其他燈）加位置，`app/lib/core/content.dart` 的 `Light` 加一個名字，`python3 street.py`。
