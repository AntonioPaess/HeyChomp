#!/bin/bash
set -euo pipefail
# Prévia isolada do redesign. Fontes da prévia ficam ao lado deste script; o resultado vai para $REVIEW_OUT.
# SOURCE_BUNDLE deve apontar para um HeyChomp.app Debug já compilado (só os recursos, como Assets.car, são copiados).
here="$(cd "$(dirname "$0")" && pwd)"
source_root="$(cd "$here/../../.." && pwd)"
q="${REVIEW_OUT:-/private/tmp/heychomp-workspace-redesign}"
source_bundle="${SOURCE_BUNDLE:-/private/tmp/heychomp-team.lxTqfq/DerivedData/Build/Products/Debug/HeyChomp.app}"
module_cache="${MODULE_CACHE:-$q/module-cache}"
review="$q/HeyChomp Inicio.app"
[ -d "$source_bundle/Contents/Resources" ] || { echo "SOURCE_BUNDLE sem recursos: $source_bundle" >&2; exit 1; }
mkdir -p "$review/Contents/MacOS" "$review/Contents/Resources" "$module_cache"
ditto "$source_bundle/Contents/Resources" "$review/Contents/Resources"
# As traduções vêm sempre da fonte atual, não do bundle de origem.
for lang in en pt-BR; do
    ditto "$source_root/Sieghart/Shared/Resources/$lang.lproj" "$review/Contents/Resources/$lang.lproj"
done
cat > "$review/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.sieghart.workspace-review</string>
<key>CFBundleExecutable</key><string>HeyChompReview</string>
<key>CFBundleName</key><string>HeyChomp Início</string>
<key>CFBundleDisplayName</key><string>HeyChomp Início</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
sources=()
while IFS= read -r file; do sources+=("$file"); done < <(rg --files "$source_root/Sieghart" -g '*.swift' | sort | sed '/\/App\//d')
xcrun swiftc -swift-version 6 -j 5 -module-cache-path "$module_cache" "${sources[@]}" \
    "$source_root/Tools/OnboardingSurfaceQA.swift" "$source_root/Tests/PlatformFixtures.swift" "$here/ReviewFixtures.swift" "$here/ReviewWorkspace.swift" \
    -o "$review/Contents/MacOS/HeyChompReview"
codesign --force --sign - "$review"
codesign --verify --deep --strict "$review"
