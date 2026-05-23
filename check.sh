#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$ROOT_DIR"

run_model_validations() {
  local script
  for script in     scripts/validate-required-files.sh     scripts/validate-paths.sh     scripts/validate-docs.sh     scripts/validate-rules.sh     scripts/validate-no-secrets.sh     scripts/validate-file-size.sh     scripts/validate-no-runtime-pkg-names.sh     scripts/validate-fixtures.sh     scripts/validate-layering.sh     scripts/validate-stack.sh; do
    [[ -x "$script" ]] || { echo "[check:modelo] ERROR: script obrigatório ausente ou sem execução: $script" >&2; exit 1; }
    "$script"
  done
}

run_model_validations

echo "==> SwiftFormat"
if command -v swiftformat >/dev/null 2>&1; then
  swiftformat --lint "$ROOT_DIR"
else
  if [ "$(uname -s)" != "Darwin" ]; then
    echo "==> SwiftFormat (ignorado: binario ausente em ambiente nao-macOS)"
  else
    (cd Tools && swift run -c release swiftformat-tool --lint "$ROOT_DIR")
  fi
fi

echo "==> SwiftLint"
if command -v swiftlint >/dev/null 2>&1; then
  SWIFTLINT_BIN="$(command -v swiftlint)"
else
  SWIFTLINT_VERSION="0.63.2"
  SWIFTLINT_URL="https://github.com/realm/SwiftLint/releases/download/${SWIFTLINT_VERSION}/SwiftLintBinary.artifactbundle.zip"
  SWIFTLINT_DIR="$ROOT_DIR/Tools/bin"
  SWIFTLINT_BIN="$SWIFTLINT_DIR/swiftlint"

  if [ ! -x "$SWIFTLINT_BIN" ]; then
    echo "==> Baixando SwiftLint ${SWIFTLINT_VERSION}"
    TMP_DIR="$ROOT_DIR/Tools/.swiftlint-tmp"
    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"
    curl -L "$SWIFTLINT_URL" -o "$TMP_DIR/swiftlint.zip"
    unzip -q "$TMP_DIR/swiftlint.zip" -d "$TMP_DIR"
    BIN_PATH="$(find "$TMP_DIR" -path "*/macos/swiftlint" -type f | head -n 1)"
    if [ -z "$BIN_PATH" ]; then
      echo "Falha ao localizar binario do SwiftLint"
      exit 1
    fi
    mkdir -p "$SWIFTLINT_DIR"
    cp "$BIN_PATH" "$SWIFTLINT_BIN"
    chmod +x "$SWIFTLINT_BIN"
    rm -rf "$TMP_DIR"
  fi
fi

"$SWIFTLINT_BIN" --strict --config "$ROOT_DIR/SwiftLint.yml" "$ROOT_DIR"

echo "==> Clean"
xcodebuild -project PulseMac.xcodeproj \
  -scheme PulseMac \
  -configuration Debug \
  -destination 'platform=macOS' \
  clean

echo "==> Build"
xcodebuild -project PulseMac.xcodeproj \
  -scheme PulseMac \
  -configuration Debug \
  -destination 'platform=macOS' \
  build

echo "==> Test"
xcodebuild -project PulseMac.xcodeproj \
  -scheme PulseMac \
  -configuration Debug \
  -destination 'platform=macOS' \
  test
