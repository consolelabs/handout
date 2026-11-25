# Product rehearsal

A rehearsal walks one journey step by step as if the feature had shipped, on a dry account, and records what a person would see: the command or action, what came back, and a verdict (pass, friction, bug). A bug found on the way is fixed in the same round when it is small, or filed.

Round 1 walked handout 0.10.0 (the multi-member tenants are on `main`) on 2026-11-25.

| Walk | Journey | Result |
|---|---|---|
| [01-agent-report.md](01-agent-report.md) | An AI agent builds a report, publishes it, the user sends the link to a client | 15 steps: 11 pass, 3 friction, 1 bug (fixed) |
| [02-member-join.md](02-member-join.md) | An admin invites a member, the member joins and publishes | 15 steps: 14 pass, 1 friction; 2 findings (one docs fix, one filed) |
| [03-bar-daily-use.md](03-bar-daily-use.md) | Daily use of Handout Bar: publish by drag, copy a link, check visitors | CLI side walked; the app screens not walked (VM down); 1 finding filed |

## What a round runs

`bash docs/product/rehearsal/walk.sh [j1] [j2] [j3]` replays the CLI legs. It uses the suite's isolation (throwaway root, config and `HOME`, stubbed `launchctl`, `systemctl`, `security` and `op`) and the dry seams (`SHARE_R2_DRY`, `SHARE_ACCESS_DRY`, `SHARE_TUNNEL=0`), so it needs no account and touches no live profile. It needs `caddy`, `jq`, `curl` and `node` on `PATH`. Live legs (a real Cloudflare account, a real upload, DNS, any message) are never part of a rehearsal: `tests/e2e*.sh` own them.

The app screens run through the app's test hooks in a VM (`mac/Tests/fixtures/popover/popover-b-shots.sh`), never on a live desktop.

## Fixed in round 1

| Finding | Fix |
|---|---|
| `handout add <missing path>` printed the usage line | `bin/handout`, test section `add: a missing path is named`, proof [../../verification/add-missing-path.md](../../verification/add-missing-path.md) |
| README example said links last 7 days; the default is 30 | `README.md` |
| `docs/setup.md` 4i left out that a member needs Handout installed first | `docs/setup.md` |

## Filed, not fixed

Each is a ready command. Run it to open the issue.

```bash
gh issue create -R consolelabs/handout --title "Handout Bar popover has no way to see a link's visitors" --body $'Goal\nA person can check how many times a link was opened from the Handout Bar popover, as they could from the classic menu.\n\nDone when\nThe row menu or Quick Look shows the result of `handout hits <id>` for an own machine link, and a swift row covers it.\n\nScope\nmac/ only. The classic menu (`LegacyMenu`) is the only caller of `ProfileArgs.hits` today and is due to go after one release; member `hits` stays out (SPEC-009 DEC-5).\n\nNotes\nFound in product rehearsal round 1, walk 3 (docs/product/rehearsal/03-bar-daily-use.md).'
gh issue create -R consolelabs/handout --title "handout add does not print when the link expires" --body $'Goal\n`handout add` prints the expiry date beside the link, so the person handing it to a client knows when it dies without running `ls`.\n\nDone when\n`bash tests/share.sh` has a row that `add` output carries `expires <date>` (or `never`) on stderr or a second line, and the link stays the first line of stdout.\n\nScope\nbin/handout cmd_add and cmd_add_r2 output; README and skill text that show add output.\n\nNotes\nThe default is 30 days. Found in product rehearsal round 1, walk 1 (docs/product/rehearsal/01-agent-report.md). Keep the first stdout line a bare link: the Handout Bar and agents read it.'
gh issue create -R consolelabs/handout --title "handout add <port> publishes a link to a port nothing listens on" --body $'Goal\nAdding a live share for a port with no listener warns before publishing, instead of handing out a dead link.\n\nDone when\nA suite row shows `handout add <free port>` prints a warning naming the port while nothing listens, still publishes (a dev server may start later), and a row shows no warning when a listener exists.\n\nScope\nbin/handout cmd_add, live branch only.\n\nNotes\nFound in product rehearsal round 1, walk 1, step 13.'
gh issue create -R consolelabs/handout --title "handout join ends on the internal member id and names no next step" --body $'Goal\nThe last line of `handout join` names the member and the tenant host and says what to run next.\n\nDone when\nA suite row shows join output carrying the member name, the host, and `handout add <file>`; docs/setup.md 4i shows the same output.\n\nScope\nbin/handout cmd_join output; docs/setup.md 4i; the members sections of tests/members.sh that grep `joined as`.\n\nNotes\nToday: `joined as m-ana-<8 hex>`. Found in product rehearsal round 1, walk 2, step 7.'
gh issue create -R consolelabs/handout --title "handout hits counts the owner's own requests" --body $'Goal\nThe owner can tell client opens from their own previews in `handout hits`.\n\nDone when\n`hits` leaves out requests from the machine itself, or takes `--others`, and a suite row covers it.\n\nScope\nbin/handout cmd_hits, tunnel profiles only; the R2 backend counts in Analytics Engine and is out of scope.\n\nNotes\nFound in product rehearsal round 1, walk 1, step 7: three client opens and one self check read as 4 hits, 3 visitors.'
```
