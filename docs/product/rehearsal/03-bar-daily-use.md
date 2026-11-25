# Walk 3: daily use of Handout Bar, publish by drag, copy a link, check visitors

Only part of this walk could run. The app's own screens (the popover, the row menu, the drop target) render through the app's test hooks inside the mac-ui VM, and the VM was down when this walk ran. What ran is the CLI side of each step, exactly the calls the app makes. What was read, not run, is marked `read`.

Walked with `walk.sh j3` against handout 0.10.0, `SHARE_TUNNEL=0`, host `s.example.test`.

Verdicts: pass, friction, bug, not walked.

| # | Action in the app | What the app calls, and what came back | Verdict |
|---|---|---|---|
| 1 | Drag a PDF onto the status item | `handout --profile default add <path>` with `SHARE_PROGRESS=1`. Six progress lines, `{"progress":{"verb":"add","step":N,"of":6,"name":...}}` for pointer, publish, access, host, gate, row, then the link. The popover's placeholder row moves on these lines | pass (CLI side). The drop overlay and the progress row itself: not walked |
| 2 | Open the popover | One read, `handout profiles --json`: `{"schema":1,"profiles":[{"name":"default",...}]}` carrying each profile's `state` | pass (CLI side) |
| 3 | Click the new row, or press Return, to copy the link | The row comes from `state`: `id`, `name`, `url`, `kind`, `expires`, `access`, `storage`, `type`, `by`, `link_state`. The copied text is `url`, the same string `add` printed | pass (CLI side). The clipboard and the "Copied" flash: not walked |
| 4 | Open the row menu | `read`: `RowActions.items` gives Copy link, Open in browser, Show in Finder, Refresh from source, Remove link, and Revoke link for another member's link. No visitor count in any of them | see F1 |
| 5 | Check visitors | There is no step in the popover. At the CLI, `handout hits <id>` answers `2 hits, 1 visitor, last <time>` after two requests from one address. `state` carries no hit count | friction: see F1 |
| 6 | Old menu (`LegacyMenu`) | `read`: its row submenu has a Hits item that runs `hits <id>` (`StatusItemController.swift`, the only caller of `ProfileArgs.hits`). The key is documented as one release only | see F1 |

## Findings

| ID | Kind | Finding | Outcome |
|---|---|---|---|
| F1 | friction | The daily-use journey ends with "check visitors", and the popover has no way to do it. README sells "Visitor counts", the CLI has `hits`, the only Bar path is the classic menu, which is due to go. When it goes, the app loses the feature with nothing in its place | Not fixed (a feature): command in the README of this folder |

Not walked, for want of the VM: the drop overlay, the progress row, the copied flash, the row menu rendering, Quick Look. Their captures exist from earlier runs under `docs/verification/share-bar/popover-b/`.
