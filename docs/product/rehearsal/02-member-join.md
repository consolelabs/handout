# Walk 2: an admin invites a member, the member joins and publishes

Walked with `walk.sh j2` against handout 0.10.0. The admin is the origin profile of `mx.example.test`; R2, Access and the Worker are the dry seams (`SHARE_R2_DRY=1`, `SHARE_ACCESS_DRY=1`) with a dry Worker that reads the same dry bucket; the member is a second `HOME` with its own Keychain stand-in. Live leg excluded: no Cloudflare account, no tunnel, no DNS, no message to anyone (the invite line stays in the log).

Verdicts: pass, friction, bug.

| # | Who | Action | What I saw | Verdict |
|---|---|---|---|---|
| 1 | admin | `setup mx.example.test --r2 --bucket mx-bucket` | `worker ... deployed`, `route`, then `ready: R2 is on ... Store this origin's publisher token: handout --profile ten api-token` | pass |
| 2 | admin | `setup ... --members --yes` | `deploy`, `marker: share.json has members:true`, `ready: members are on ...: handout --profile ten member add <name>` | pass: each step ends on the next command |
| 3 | admin | `member add ana --machine` with no minter token | `this needs the minter token ...: set SHARE_MINTER_TOKEN, or store a command that prints it with handout --profile ten minter-token --cmd '<command>'; nothing was changed`. With `SHARE_ERROR_JSON=1` the same plus a JSON line with code `minter_token_missing` and `next` | pass |
| 4 | admin | `member add ana --machine --port N` | Seven labelled lines (member, token, tunnel, service, deploy, invited) and last `handout join mx.example.test <20 characters>` with "send this line to them once (it works once)" and the invite expiry | pass |
| 5 | admin | `member ls` | `ana: invited`, id, mode, `offline (0 connector(s))`, `bound=true`, token and invite expiry, `token slots: 49 of 50 free` | pass |
| 6 | member | `handout join mx.example.test <wrong code>` | `this invite was already used or never existed; ask the admin: handout member rotate <your name> (handout member invite <your name> for a cloud member)`, exit 1 | pass |
| 7 | member | `handout join mx.example.test <code>` | One line: `joined as m-ana-<8 hex>` | friction: see F2 |
| 8 | member | The same line again (the message was forwarded) | The same "already used" refusal as step 6 | pass |
| 9 | member | `handout status` | `serving (pid N) on mx.example.test: links are live`, `role: member`, `member: ana (m-ana-..., machine): active, token expires ...`, `no shares` | pass |
| 10 | member | `handout add report.txt` | `https://mx.example.test/<id>/report.txt` | pass |
| 11 | member | `handout ls`, `handout hits <id>` | One row with expiry and source; `0 hits, 0 visitors` | pass |
| 12 | visitor | The link through the dry Worker and the member's Caddy | `200 /<id>/report.txt` | pass |
| 13 | admin | `ls` | The member's link with `origin=ana  served by ana's machine  state=offline` (the dry tunnel has no connector, so offline is right here) | pass |
| 14 | admin | `member pause ana`, visitor request, `member resume ana` | Pause line names what happens ("its machine links answer 503 paused; its cloud links keep serving") and the undo; the visitor got 503; resume restored serving | pass |
| 15 | member | `handout leave` | `unpublished <id>`, then `left: mx.example.test (...); this machine's links, keys and config are gone; its cloud links stay until they expire` | pass |

## Findings

| ID | Kind | Finding | Outcome |
|---|---|---|---|
| F1 | friction (docs) | The invite line is all the admin sends, but the member's Mac must already have Handout and the Keychain. `docs/setup.md` 4i said "Paste the line on the member's Mac" with no install step, so a member without the CLI gets `command not found` | Fixed in `docs/setup.md` 4i: send the install line with the join line, members run macOS |
| F2 | friction | `joined as m-ana-<8 hex>` shows the internal member id, not the name `ana`, and names neither the tenant host nor the next command. The member has to read the docs to learn `handout add ./file` | Not fixed (output change): command in the README of this folder |

Not walked: an expired invite (`invite_expired`), a tampered code, a join over a busy port, a rotate. The suite covers these (`members: member machine (R7) and join`).
