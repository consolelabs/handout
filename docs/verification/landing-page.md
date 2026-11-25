# Proof of done: landing-page

Branch `feat/landing-page`. A static landing page under `site/`: one HTML file, no script, no external font, no pinned domain. It changes no CLI, Worker or app behavior, and nothing deploys it. The check is `site/check.sh`, an offline page check.

## Green run
```
Command: bash site/check.sh
Exit: 0
Output:
site check: PASS
Verdict: PASS
```

```
Command: shellcheck site/check.sh
Exit: 0
Verdict: PASS
```

## Negative control
A copy of `site/` with three breaks: the demo GIF path renamed, the FAQ anchor retargeted at a missing id, and a third-party script appended.
```
Command: bash <copy>/site/check.sh
Exit: 1
Output:
FAIL  missing file: assets/gone.gif
FAIL  anchor has no target: #nope
FAIL  a script, external stylesheet, font or remote url() is loaded
FAIL  unexpected host: cdn.example.org
Verdict: RED as expected (each break is named, so the check proves local links, anchors, no third-party load and no unknown host)
```
Restored (the real `site/`):
```
Command: bash site/check.sh
Exit: 0
Output:
site check: PASS
Verdict: PASS
```

## Rendering
The mac-ui guest had no network when this was verified, so the static page was rendered on the host with the estate's headless HTML check (a private headless browser on a localhost server, no app run).
```
Command: tools/interactive-concept-board/bin/verify --shots docs/verification/landing-page site/index.html
Exit: 0
Output:
WARN  index  self-test no self-test  console-errors 0   moved n/a  overflow no
0 pass, 1 warn, 0 fail
Verdict: PASS (WARN only because a page has no board self-test; console errors 0, no horizontal overflow at 400 px)
```
Full-page screenshots, read and checked by eye:

| File | Width | Mode |
|---|---|---|
| `docs/verification/landing-page/desktop-1280-light.png` | 1280 | light |
| `docs/verification/landing-page/desktop-1280-dark.png` | 1280 | dark |
| `docs/verification/landing-page/phone-400-light.png` | 400 | light |
| `docs/verification/landing-page/phone-400-dark.png` | 400 | dark |

The demo GIF shows its first frame in a still screenshot, so the terminal pane looks nearly empty there; it plays in a browser. The dark shots force the dark palette on a scratch copy of the page, because headless capture cannot set the color scheme.
