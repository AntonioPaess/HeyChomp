#!/bin/sh
# Compila o protótipo, instala num simulador e captura todas as telas nos dois temas.
# Uso: Tools/capture-screens.sh [nome-do-simulador]   (padrão: iPhone 17)
# Saída: Docs/telas-claro.png e Docs/telas-escuro.png (precisa de Python 3 com Pillow).
set -e
cd "$(dirname "$0")/.."
DEVICE="${1:-iPhone 17}"
BUNDLE=com.sieghart.heychomp.mobile.prototype
DD=/tmp/heychomp-ios-dd
OUT=$(mktemp -d /tmp/heychomp-shots.XXXXXX)

xcodebuild -project HeyChompMobile.xcodeproj -scheme HeyChompMobile -configuration Debug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DD" build -quiet
UDID=$(xcrun simctl list devices available | grep "    $DEVICE (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
[ -n "$UDID" ] || { echo "Simulador '$DEVICE' não encontrado"; exit 1; }
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl install "$UDID" "$DD/Build/Products/Debug-iphonesimulator/HeyChompMobile.app"
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryLevel 100 --cellularBars 4 >/dev/null 2>&1 || true

for theme in light dark; do
  for screen in onboarding home chat conversations voice team chomp rita gantt elinor ada toni settings pair widgets; do
    xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
    sleep 1
    xcrun simctl launch "$UDID" "$BUNDLE" -startScreen "$screen" -appearance "$theme" >/dev/null
    sleep 4
    xcrun simctl io "$UDID" screenshot "$OUT/$screen-$theme.png" >/dev/null 2>&1
  done
done

python3 Tools/compose-screens.py "$OUT" Docs
echo "Capturas individuais em $OUT"
