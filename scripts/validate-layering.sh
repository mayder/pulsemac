#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
log "validando arquitetura por camadas"
enabled="$(toml_string_value quality.layering enabled)"
if [[ "$enabled" != "true" ]]; then log "quality.layering.enabled=false; pulando validação de camadas no modelo"; exit 0; fi
if [[ "${STRICT_SWIFT_LAYERING:-0}" != "1" ]]; then
  log "modo legado: layering Swift estrito desativado; use STRICT_SWIFT_LAYERING=1"
  exit 0
fi
if find Sources/Domain -type f -name '*.swift' -print0 | xargs -0 grep -nE "import (SwiftUI|AppKit|SQLite3|WidgetKit|UserNotifications)"; then
  fail "Sources/Domain não deve importar SwiftUI/AppKit/SQLite3/WidgetKit/UserNotifications"
fi
