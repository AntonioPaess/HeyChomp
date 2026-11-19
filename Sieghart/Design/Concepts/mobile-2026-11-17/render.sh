#!/bin/sh
# Renderiza os quadros do conceito mobile em PNG (2x) com o Chrome headless.
set -e
cd "$(dirname "$0")"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
render() { # board theme width height
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 \
    --allow-file-access-from-files --virtual-time-budget=3000 \
    --window-size="$3,$4" --screenshot="$PWD/$1-$2.png" "file://$PWD/concept.html?board=$1&theme=$2" >/dev/null 2>&1
}
for t in light dark; do
  render app "$t" 1980 1240
  render widgets "$t" 1520 1240
  render lock "$t" 1520 1240
  render chars "$t" 2000 1240
  render mix "$t" 2000 1240
done
ls -1 *.png
