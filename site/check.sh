#!/usr/bin/env bash
# Check the landing page offline: every local href/src resolves, every in-page anchor
# has a target, no script or external stylesheet or font is loaded, and no em or en dash.
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
page="$here/index.html"
fail=0

bad() { echo "FAIL  $*"; fail=1; }

[ -f "$page" ] || { echo "FAIL  $page is missing"; exit 1; }

# local files named by href or src
while IFS= read -r ref; do
  case "$ref" in
    http://*|https://*|mailto:*|\#*) continue ;;
  esac
  [ -e "$here/${ref%%[?#]*}" ] || bad "missing file: $ref"
done < <(grep -oE '(href|src)="[^"]*"' "$page" | sed -E 's/^(href|src)="//; s/"$//')

# in-page anchors
while IFS= read -r anchor; do
  grep -q "id=\"$anchor\"" "$page" || bad "anchor has no target: #$anchor"
done < <(grep -oE 'href="#[^"]+"' "$page" | sed -E 's/^href="#//; s/"$//' | sort -u)

# nothing third-party loads: no script, no stylesheet link, no font or image from another host
if grep -qiE '<script|<link[^>]*rel="?stylesheet|@import|@font-face|url\(https?:' "$page"; then
  bad "a script, external stylesheet, font or remote url() is loaded"
fi
if grep -oE '<(img|source|iframe|link)[^>]*(src|href)="https?://[^"]*"' "$page" | grep -q .; then
  bad "an element loads a remote resource"
fi

# no em dash or en dash
if grep -q $'\xe2\x80\x93\|\xe2\x80\x94' "$page"; then
  bad "em or en dash in index.html"
fi

# no hardcoded product domain: only the example hostnames, the repo, and console.so (the publisher)
while IFS= read -r host; do
  case "$host" in
    github.com|raw.githubusercontent.com|console.so|s.example.com|example.com|trycloudflare.com|developers.cloudflare.com) ;;
    *) bad "unexpected host: $host" ;;
  esac
done < <(grep -oE 'https?://[A-Za-z0-9.-]+' "$page" | sed -E 's#^https?://##' | sort -u)

# canonical and og:url would pin a domain
if grep -qiE 'rel="canonical"|og:url' "$page"; then
  bad "canonical or og:url pins a domain"
fi

if [ "$fail" -eq 0 ]; then echo "site check: PASS"; else exit 1; fi
