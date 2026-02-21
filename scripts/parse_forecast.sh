#!/bin/bash
# parse_forecast.sh: Parse JMA forecast JSON into human-readable format
# Reads JSON from stdin or first argument (file path)
#
# Usage:
#   bash fetch_forecast.sh 130000 forecast | bash parse_forecast.sh
#   bash parse_forecast.sh forecast_data.json

set -euo pipefail

if [ -n "${1:-}" ] && [ -f "${1}" ]; then
  JSON=$(cat "$1")
else
  JSON=$(cat -)
fi

# Check if jq is available
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

# Detect if this is overview (object) or forecast (array)
TYPE=$(echo "$JSON" | jq -r 'type')

if [ "$TYPE" = "object" ]; then
  # Overview format
  echo "=== 天気概況 ==="
  echo ""
  echo "発表元: $(echo "$JSON" | jq -r '.publishingOffice')"
  echo "発表日時: $(echo "$JSON" | jq -r '.reportDatetime')"
  echo "対象地域: $(echo "$JSON" | jq -r '.targetArea')"
  echo ""
  echo "--- 概況 ---"
  echo "$JSON" | jq -r '.text' | sed 's/　/ /g'
  exit 0
fi

# Forecast array format
echo "=== 天気予報 ==="
echo ""

# First element: 3-day forecast
echo "$JSON" | jq -r '
  .[0] |
  "発表元: \(.publishingOffice)",
  "発表日時: \(.reportDatetime)",
  ""
'

# Weather forecasts per area
echo "--- 地域別天気予報（3日間） ---"
echo ""

echo "$JSON" | jq -r '
  .[0].timeSeries[0] as $ts |
  ($ts.timeDefines | map(split("T")[0])) as $dates |
  $ts.areas[] |
  "【\(.area.name)】",
  (range($dates | length) as $i |
    "  \($dates[$i]): \(.weathers[$i] // .weatherCodes[$i])"
  ),
  (if .winds then
    (range($dates | length) as $i |
      "    風: \(.winds[$i])"
    )
  else empty end),
  ""
'

# Precipitation probability
if echo "$JSON" | jq -e '.[0].timeSeries[1].areas[0].pops' &>/dev/null; then
  echo "--- 降水確率 ---"
  echo ""
  echo "$JSON" | jq -r '
    .[0].timeSeries[1] as $ts |
    ($ts.timeDefines | map(split("T") | .[0] + " " + (.[1] | split("+")[0] | .[0:5]))) as $times |
    $ts.areas[] |
    "【\(.area.name)】",
    (range($times | length) as $i |
      "  \($times[$i]): \(.pops[$i])%"
    ),
    ""
  '
fi

# Temperature
if echo "$JSON" | jq -e '.[0].timeSeries[2].areas[0].temps' &>/dev/null; then
  echo "--- 気温 ---"
  echo ""
  echo "$JSON" | jq -r '
    .[0].timeSeries[2] as $ts |
    ($ts.timeDefines | map(split("T") | .[0] + " " + (.[1] | split("+")[0] | .[0:5]))) as $times |
    $ts.areas[] |
    "【\(.area.name)】",
    (range($times | length) as $i |
      "  \($times[$i]): \(.temps[$i])°C"
    ),
    ""
  '
fi

# Weekly forecast (second element)
if echo "$JSON" | jq -e '.[1].timeSeries[0]' &>/dev/null; then
  echo "--- 週間予報 ---"
  echo ""
  echo "$JSON" | jq -r '
    .[1].timeSeries[0] as $ts |
    ($ts.timeDefines | map(split("T")[0])) as $dates |
    $ts.areas[] |
    "【\(.area.name)】",
    (range($dates | length) as $i |
      "  \($dates[$i]): 天気コード=\(.weatherCodes[$i]) 降水確率=\(.pops[$i])% 信頼度=\(.reliabilities[$i] // "—")"
    ),
    ""
  '

  # Weekly temperature
  if echo "$JSON" | jq -e '.[1].timeSeries[1].areas[0].tempsMax' &>/dev/null; then
    echo "--- 週間気温予報 ---"
    echo ""
    echo "$JSON" | jq -r '
      .[1].timeSeries[1] as $ts |
      ($ts.timeDefines | map(split("T")[0])) as $dates |
      $ts.areas[] |
      "【\(.area.name)】",
      (range($dates | length) as $i |
        "  \($dates[$i]): 最低=\(if .tempsMin[$i] == "" or .tempsMin[$i] == null then "—" else .tempsMin[$i] + "°C" end)  最高=\(if .tempsMax[$i] == "" or .tempsMax[$i] == null then "—" else .tempsMax[$i] + "°C" end)"
      ),
      ""
    '
  fi
fi

