---
name: jma-weather-forecast
description: "日本の天気予報を気象庁APIから取得。3日間予報、週間予報、天気概況を都道府県・地域別に表示。Japan weather forecast via JMA (Japan Meteorological Agency) API — 3-day forecast, weekly forecast, and weather overview by prefecture."
metadata:
  openclaw:
    requires:
      bins:
        - curl
        - jq
    emoji: "🌦️"
---

# JMA Weather Forecast (気象庁天気予報)

日本の天気予報を気象庁の公開JSONデータから取得するスキルです。APIキー不要で、全国47都道府県の天気情報にアクセスできます。

## When to Use

- ユーザーが日本の天気予報を知りたいとき
- 「東京の天気は？」「明日の大阪の天気を教えて」のような質問
- 週間天気予報や天気概況を確認したいとき
- "What's the weather in Tokyo?" or any Japan weather query

## Instructions

### 1. Determine the Area Code

ユーザーが指定した都道府県名から `area_codes.json` を参照してエリアコードを特定する。

- 都道府県名は部分一致でOK（「東京」→「東京都」→ `130000`）
- 北海道と沖縄は複数の地域に分かれている点に注意
- ユーザーが市区町村名を指定した場合は、所属する都道府県を推定する（例：「横浜市」→ 神奈川県 → `140000`）

### 2. Fetch Weather Data

目的に応じて以下のモードを選ぶ:

**3日間予報 + 週間予報（デフォルト）:**
```bash
bash scripts/fetch_forecast.sh {AREA_CODE} forecast | bash scripts/parse_forecast.sh
```

**天気概況（テキスト形式の気象解説）:**
```bash
bash scripts/fetch_forecast.sh {AREA_CODE} overview | bash scripts/parse_forecast.sh
```

**週間概況:**
```bash
bash scripts/fetch_forecast.sh {AREA_CODE} week | bash scripts/parse_forecast.sh
```

### 3. Present Results

取得したデータを以下の形式でユーザーに提示する:

- **日本語で回答する**（ユーザーが英語で聞いた場合はその言語で回答）
- 天気、気温、降水確率を簡潔にまとめる
- 週間予報の天気コード（数字）は以下の対応で日本語に変換する:
  - `100` = 晴れ, `101` = 晴時々曇, `102` = 晴一時雨
  - `200` = 曇り, `201` = 曇時々晴, `202` = 曇一時雨
  - `300` = 雨, `301` = 雨時々晴, `302` = 雨時々曇
  - `400` = 雪, `401` = 雪時々晴, `402` = 雪時々曇
  - 詳細は https://www.jma.go.jp/bosai/forecast/ の天気アイコンを参照
- 必要に応じて「傘を持って行ったほうがいい」等の実用的アドバイスを添える

### Error Handling

- エリアコードが不明な場合: ユーザーに都道府県名を確認する
- APIが応答しない場合: 気象庁サーバーの一時的な問題として案内する
- データ構造が想定外の場合: 生のJSONを確認してベストエフォートでパースする

## Examples

**Example 1: 基本的な天気予報**
User: 「東京の天気を教えて」
→ エリアコード `130000` で forecast モードを実行

**Example 2: 天気概況**
User: 「関東の天気概況は？」
→ エリアコード `130000`（東京）で overview モードを実行。概況は広域の情報を含む。

**Example 3: 週間予報**
User: 「来週の大阪の天気は？」
→ エリアコード `270000` で forecast モードを実行し、週間予報セクションを提示

**Example 4: English query**
User: "Will it rain in Saitama tomorrow?"
→ Area code `110000`, forecast mode, answer in English

## Data Source

- 気象庁防災情報 JSON（非公式API、政府標準利用規約に準拠して利用可）
- データは気象庁により1日数回更新される
- 公式APIではないため、仕様変更の可能性あり

