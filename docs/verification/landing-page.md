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
Screenshots at 400 px and 1280 px, light and dark, are rendered in the mac-ui guest and saved under `docs/verification/landing-page/` when the guest queue allows (see the PR).
