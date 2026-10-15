#!/usr/bin/env bash
# Uçtan uca testi, .env.example içindeki test hesabıyla çalıştırır.
# Kullanım: tool/run_integration_test.sh [device-id] [ek flutter test argümanları...]
# Örnek:    tool/run_integration_test.sh 9F01E328-... --dart-define=RUN_AI_TEST=true
set -euo pipefail

cd "$(dirname "$0")/.."

ENV_FILE="${ENV_FILE:-.env.example}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "$ENV_FILE bulunamadı (username=... / password=... satırları gerekli)" >&2
  exit 1
fi

read_key() { grep -E "^$1=" "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r'; }
EMAIL="$(read_key username)"
PASSWORD="$(read_key password)"

DEVICE_ARGS=()
if [[ $# -gt 0 && "$1" != --* ]]; then
  DEVICE_ARGS=(-d "$1")
  shift
fi

flutter test integration_test/app_flow_test.dart \
  "${DEVICE_ARGS[@]+"${DEVICE_ARGS[@]}"}" \
  --dart-define=TEST_EMAIL="$EMAIL" \
  --dart-define=TEST_PASSWORD="$PASSWORD" \
  "$@"
