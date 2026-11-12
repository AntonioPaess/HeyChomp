#!/bin/bash
set -euo pipefail
q="/private/tmp/heychomp-workspace-redesign"
source_root="/Users/antoniopaesdeandrade/.codex/worktrees/heychomp-design/heychomp-pr11.7y6x55/Sieghart"
source_bundle="/private/tmp/heychomp-team.lxTqfq/DerivedData/Build/Products/Debug/HeyChomp.app"
review="$q/HeyChomp Inicio.app"
mkdir -p "$review/Contents/MacOS" "$review/Contents/Resources"
ditto "$source_bundle/Contents/Resources" "$review/Contents/Resources"
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
xcrun swiftc -swift-version 6 -j 5 -module-cache-path /private/tmp/heychomp-design-qa.KwYCu9/catalog-module-cache "${sources[@]}" \
    "$source_root/Tools/OnboardingSurfaceQA.swift" "$source_root/Tests/PlatformFixtures.swift" "$q/ReviewFixtures.swift" "$q/ReviewWorkspace.swift" \
    -o "$review/Contents/MacOS/HeyChompReview"
codesign --force --sign - "$review"
codesign --verify --deep --strict "$review"
