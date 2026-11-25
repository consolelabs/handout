#!/bin/bash
# promo-shots.sh: the promo screenshot set of Handout Bar, for the site and launch posts. It is not
# verification evidence (that sits in docs/verification/share-bar/). Neutral demo data only: the host
# is s.example.com, the files are made up, the fake CLI answers from this repo's fixtures.
#
# Four screens, light and dark, each on a padded gradient frame (frame.swift):
#   popover-calm       the popover with every link answering
#   row-menu           one row's menu open
#   drag-to-publish    the drop target while a file is dragged over the popover
#   settings           the General pane of Settings
#
# Usage: mac/Tests/fixtures/promo/promo-shots.sh <out dir>
# The popover screens render offscreen through the app's DEBUG hook (no pointer or key input). The
# Settings screen is a window capture (`screencapture -l`), so it needs Screen Recording for the terminal.
# Needs jq, swiftc and what settings/run-shots.sh needs.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
MAC="$(cd "$HERE/../../.." && pwd)"
FIXTURES="$MAC/Tests/fixtures"
OUT="${1:?usage: promo-shots.sh <out dir>}"
WORK="$MAC/build/promo"
RAW="$WORK/raw"
mkdir -p "$OUT" "$RAW" "$WORK/gone"

FRAME="$WORK/frame"
swiftc -O "$HERE/frame.swift" -o "$FRAME"

# popover width in points; the capture's pixel width over it is the display scale
POPOVER_POINTS=340

export SHOTS_SCENARIO=promo
bash "$FIXTURES/popover/popover-b-shots.sh" "$RAW" calm drop
SHOTS_MENU_ROW=pr0001 bash "$FIXTURES/popover/popover-b-shots.sh" "$RAW" menu
SHOTS_OUT="$RAW" bash "$FIXTURES/settings/run-shots.sh" general-tab

frame_one() { # frame_one <raw name> <out name> <popover|window>
  local mode raw out width radius=0
  for mode in light dark; do
    raw="$RAW/$1-$mode.png"
    out="$OUT/$2-$mode.png"
    [[ -s $raw ]] || { echo "promo-shots.sh: missing $raw" >&2; exit 1; }
    if [[ $3 == popover ]]; then
      width="$(sips -g pixelWidth "$raw" | awk '/pixelWidth/ {print $2}')"
      radius=$(( 10 * width / POPOVER_POINTS ))
    fi
    "$FRAME" "$mode" "$radius" "$raw" "$out"
  done
}

frame_one calm popover-calm popover
frame_one drop drag-to-publish popover
frame_one menu row-menu popover
frame_one 4b-general-tab settings window
