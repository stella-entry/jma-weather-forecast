#!/bin/bash
# jma-weather-forecast: Fetch weather forecast from Japan Meteorological Agency
# Usage: bash fetch_forecast.sh <area_code> [overview|forecast|week]
#
# Examples:
#   bash fetch_forecast.sh 130000 forecast   # Tokyo 3-day forecast
#   bash fetch_forecast.sh 110000 overview   # Saitama weather overview
#   bash fetch_forecast.sh 130000 week       # Tokyo weekly overview

set -euo pipefail

AREA_CODE="${1:?Usage: fetch_forecast.sh <area_code> [overview|forecast|week]}"
MODE="${2:-forecast}"
BASE_URL="https://www.jma.go.jp/bosai/forecast/data"

case "$MODE" in
  overview)
    URL="${BASE_URL}/overview_forecast/${AREA_CODE}.json"
    ;;
  forecast)
    URL="${BASE_URL}/forecast/${AREA_CODE}.json"
    ;;
  week)
    URL="${BASE_URL}/overview_week/${AREA_CODE}.json"
    ;;
  *)
    echo "Error: Unknown mode '$MODE'. Use: overview, forecast, or week" >&2
    exit 1
    ;;
esac

RESPONSE=$(curl -sf --max-time 10 "$URL") || {
  echo "Error: Failed to fetch data from JMA API. Area code '${AREA_CODE}' may be invalid." >&2
  exit 1
}

echo "$RESPONSE"

