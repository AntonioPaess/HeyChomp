#!/bin/bash
set -euo pipefail
source_bundle="${1:?Pass a verified HeyChomp.app build path}"
tool_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
destination="/Applications/HeyChomp.app"
info="$source_bundle/Contents/Info.plist"
[[ "$(/usr/bin/plutil -extract CFBundleIdentifier raw "$info")" == com.sieghart.app ]]
/usr/bin/codesign --verify --deep --strict "$source_bundle"
/bin/bash "$tool_root/Tests/verify-built-app.sh" "$source_bundle"
installed=''
for bundle in "$destination" /Applications/Chomp.app /Applications/Sieghart.app; do
    [[ -e "$bundle" ]] || continue
    if [[ -n "$installed" ]]; then
        echo 'Multiple installed names exist. Identify the canonical copy before updating.' >&2
        exit 1
    fi
    installed="$bundle"
done
if [[ -n "$installed" ]]; then
    /bin/bash "$tool_root/Tools/check-update-identity.sh" "$installed" "$source_bundle"
fi
if /usr/bin/pgrep -x 'HeyChomp|Chomp|Sieghart' >/dev/null; then
    echo 'Quit the running app before installing. Its saved state will be retained.' >&2
    exit 1
fi
python3 "$tool_root/Tools/hold-awake-during-update.py" check
staging="$(/usr/bin/mktemp -d /Applications/.heychomp-install.XXXXXX)"
trap '/bin/rm -rf "$staging"' EXIT
/usr/bin/ditto "$source_bundle" "$staging/HeyChomp.app"
/usr/bin/codesign --verify --deep --strict "$staging/HeyChomp.app"
backup_bundle=''
if [[ -n "$installed" ]]; then
    backup="$(/usr/bin/mktemp -d /private/tmp/heychomp-previous-app.XXXXXX)"
    backup_bundle="$backup/${installed##*/}"
    /bin/mv "$installed" "$backup_bundle"
    echo "Previous app preserved at $backup_bundle"
fi
if ! /bin/mv "$staging/HeyChomp.app" "$destination"; then
    if [[ -n "$backup_bundle" && ! -e "$installed" ]]; then
        /bin/mv "$backup_bundle" "$installed"
    fi
    exit 1
fi
register='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'
"$register" -u "$source_bundle" || true
# Xcode products are disposable launch targets. Leave every file intact, but
# stop offering old build paths as alternate copies of the installed app.
for old_bundle in \
    "$HOME"/Library/Developer/Xcode/DerivedData/HeyChomp-*/Build/Products/Debug/HeyChomp.app \
    "$HOME"/Library/Developer/Xcode/DerivedData/HeyChomp-*/Build/Products/Release/HeyChomp.app \
    "$HOME"/Library/Developer/Xcode/DerivedData/Chomp-*/Build/Products/Debug/Chomp.app \
    "$HOME"/Library/Developer/Xcode/DerivedData/Chomp-*/Build/Products/Release/Chomp.app \
    "$HOME"/Library/Developer/Xcode/DerivedData/Sieghart-*/Build/Products/Debug/Sieghart.app \
    "$HOME"/Library/Developer/Xcode/DerivedData/Sieghart-*/Build/Products/Release/Sieghart.app \
    /private/tmp/heychomp-*/Build/Products/Debug/HeyChomp.app \
    /private/tmp/chomp-*/Build/Products/Debug/Chomp.app \
    /private/tmp/sieghart-*/Build/Products/Debug/Sieghart.app; do
    [[ -d "$old_bundle" ]] || continue
    identifier="$(/usr/bin/plutil -extract CFBundleIdentifier raw "$old_bundle/Contents/Info.plist" 2>/dev/null || true)"
    if [[ "$identifier" == com.sieghart.app ]]; then
        "$register" -u "$old_bundle" || true
    fi
done
"$register" -f "$destination"
echo "Installed and registered $destination"
echo 'Launch with Tools/launch-current-app.sh; never execute Contents/MacOS/HeyChomp directly.'
