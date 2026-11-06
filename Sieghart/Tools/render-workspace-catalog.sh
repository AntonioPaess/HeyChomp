#!/bin/bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source_bundle="${1:?Pass the verified app bundle for resources}"
output="${2:?Pass a new output directory}"
mode="${3:-workspace}"
case "$mode" in workspace|chat-states|audio|review|artifacts) ;; *) echo 'Choose workspace, chat-states, audio, review or artifacts.' >&2; exit 1 ;; esac
[[ ! -e "$output" ]] || { echo 'Use a new catalog directory.' >&2; exit 1; }
/bin/bash "$project_root/Tests/verify-built-app.sh" "$source_bundle"
catalog_root="$(/usr/bin/mktemp -d /private/tmp/sieg-design-catalog.XXXXXX)"
trap '/bin/rm -rf "$catalog_root"' EXIT
bundle="$catalog_root/WorkspaceCatalog.app"
/bin/mkdir -p "$bundle/Contents/MacOS"
/usr/bin/ditto "$source_bundle/Contents/Resources" "$bundle/Contents/Resources"
cat > "$bundle/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleIdentifier</key><string>com.sieghart.design-catalog.exporter</string><key>CFBundleExecutable</key><string>WorkspaceCatalog</string><key>CFBundlePackageType</key><string>APPL</string><key>LSUIElement</key><true/></dict></plist>
PLIST
sources=()
while IFS= read -r file; do sources+=("$file"); done < <(rg --files "$project_root/Sieghart" -g '*.swift' | sort | sed '/\/App\//d')
xcrun swiftc -swift-version 6 -module-cache-path /private/tmp/sieghart-check-module-cache \
    "${sources[@]}" "$project_root/Tests/PlatformFixtures.swift" "$project_root/Tests/WorkspaceCatalog.swift" \
    -o "$bundle/Contents/MacOS/WorkspaceCatalog"
# This is an isolated, offscreen exporter with no resident app entry point,
# screen capture, microphone, models, providers or hardware operations.
"$bundle/Contents/MacOS/WorkspaceCatalog" "$source_bundle" "$output" "$mode"
python3 - "$project_root" "$output" <<'PY'
import hashlib, json, pathlib, sys
root, output = map(pathlib.Path, sys.argv[1:])
files = list((root / "Sieghart").rglob("*.swift")) + [root / "Tests/WorkspaceCatalog.swift", root / "Tests/PlatformFixtures.swift"]
record = {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(files)}
(output / "source-manifest.json").write_text(json.dumps(record, indent=2) + "\n")
PY
