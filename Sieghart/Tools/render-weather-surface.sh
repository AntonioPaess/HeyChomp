#!/bin/bash
# Native, silent, offscreen verification using the production artwork catalog.
# Usage: bash Tools/render-weather-surface.sh /path/HeyChomp.app /tmp/output [--stills]
set -euo pipefail
source_root="$(cd "$(dirname "$0")/.." && pwd)"
production="$1"
output="$2"
shift 2
bundle="$output/SurfaceRender.app"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources"
ditto "$production/Contents/Resources" "$bundle/Contents/Resources"
cat > "$bundle/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleIdentifier</key><string>com.sieghart.weather-surface-render</string><key>CFBundleExecutable</key><string>ClimateRender</string><key>CFBundlePackageType</key><string>APPL</string><key>LSUIElement</key><true/></dict></plist>
PLIST
sources=()
while IFS= read -r file; do sources+=("$file"); done < <(rg --files "$source_root/Sieghart" -g '*.swift' | sort | sed '/\/App\//d')
xcrun swiftc -swift-version 6 -j 4 -module-cache-path "$output/module-cache" "${sources[@]}" "$source_root/Tools/WeatherSurfaceQA.swift" -o "$bundle/Contents/MacOS/ClimateRender"
"$bundle/Contents/MacOS/ClimateRender" "$output/renders" "$@"
