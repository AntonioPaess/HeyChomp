#!/bin/sh
# Gera os ícones e renderiza a prancha (Chrome headless, 2x).
set -e
cd "$(dirname "$0")"
python3 generate.py
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --hide-scrollbars \
  --force-device-scale-factor=2 --allow-file-access-from-files --virtual-time-budget=3000 \
  --window-size=2000,1100 --screenshot="$PWD/prancha-icones.png" "file://$PWD/board.html" >/dev/null 2>&1
echo "prancha-icones.png"
