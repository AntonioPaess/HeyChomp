#!/bin/bash
set -euo pipefail

installed="${1:?Pass the installed app bundle}"
candidate="${2:?Pass the candidate app bundle}"
for bundle in "$installed" "$candidate"; do
    /usr/bin/codesign --verify --deep --strict "$bundle"
    [[ "$(/usr/bin/plutil -extract CFBundleIdentifier raw "$bundle/Contents/Info.plist")" == com.sieghart.app ]]
done

team() {
    /usr/bin/codesign -dv "$1" 2>&1 | /usr/bin/awk -F= '$1 == "TeamIdentifier" { print $2 }'
}
requirement() {
    /usr/bin/codesign -d -r- "$1" 2>&1 | /usr/bin/sed -n 's/.*designated => //p'
}

installed_team="$(team "$installed")"
candidate_team="$(team "$candidate")"
# One migration from the older ad-hoc builds is allowed. Its new macOS
# permission consent is still required; this never copies or edits TCC state.
if [[ -z "$installed_team" || "$installed_team" == 'not set' ]]; then
    echo 'Signature checked. Existing ad-hoc build has no stable team identity to preserve.'
    exit 0
fi
if [[ "$candidate_team" != "$installed_team" ]]; then
    echo 'Update stopped: preserve the installed development signing team; an ad-hoc or other-team build can lose its permissions.' >&2
    exit 1
fi
installed_requirement="$(requirement "$installed")"
if [[ -z "$installed_requirement" || "$installed_requirement" != "$(requirement "$candidate")" ]]; then
    echo 'Update stopped: the signing requirement changed. Use the same development identity before replacing the app.' >&2
    exit 1
fi
echo 'Stable signing identity preserved.'
