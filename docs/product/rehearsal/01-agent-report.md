# Walk 1: an agent builds a report, publishes it, the user sends the link to a client

Walked with `walk.sh j1` against handout 0.10.0, a throwaway root and config, `SHARE_TUNNEL=0`, host `s.example.test`. A local request with a `Host` header and a `Cf-Connecting-Ip` header stands in for the client at the edge. Live leg excluded: nothing reached Cloudflare, DNS or a real host.

Verdicts: pass, friction (works, but a person stalls or guesses), bug.

| # | Action | What I saw | Verdict |
|---|---|---|---|
| 1 | Agent on a machine with no setup: `handout state` | JSON with `state: not_setup`, `role: none`, `serve.phase: not_setup`. The skill tells the agent to stop here and tell the user | pass |
| 2 | Same machine: `handout add report.html` | `handout: no setup yet: run 'handout setup <hostname>' or 'handout setup --quick'` | pass: names both ways out |
| 3 | `handout skill --install` | `installed .../.claude/skills/handout/SKILL.md`, 156 lines: state first, `role` and `serve` tables, error codes, rules for agents | pass |
| 4 | Agent reads `handout state` on a set-up host | `state: stopped` before the first add, host `s.example.test`, `shares: []` | pass |
| 5 | `handout add report.html` | `https://s.example.test/<id>/report.html` then `serving in the background (pid N); handout stop to end`. The link is first line. No expiry shown | friction: see F2 |
| 6 | Client opens the link, twice from one address, once from another | 200 each. Site root, a wrong id and a dotfile path answer 404 | pass |
| 7 | User asks "did the client open it?": `handout hits <id>` and `handout hits <pasted link>` | `4 hits, 3 visitors, last <time>`. Both forms of the argument work | pass; friction F3 |
| 8 | `handout ls`, `handout status` | One row per share with type, `by=`, link, id, size, added, expiry (30 days out), source path | pass |
| 9 | Agent revises the report: `handout refresh <id>` | `refreshed <id> from <path>`; the client's next load shows the new text under the same link | pass |
| 10 | Client must not forward it: `handout add report.html --access email:client@example.com` with no API token | Names the missing token, then prints `handout api-token`, the `--cmd` form for a token already held, and the prefilled form link | pass |
| 11 | Markdown report and a folder with a `.env`: `handout add notes.md`, `handout add --ttl 3d pack` | `.../notes.html` (rendered), `.../pack/`; the `.env` is not copied | pass |
| 12 | Agent mistake: `handout add missing.pdf` | Before the fix: `handout: usage: handout add [--ttl 7d] ...`, the same line as for a bad flag. After the fix: `handout: no such file or folder: <path>; nothing was published` | bug, fixed in this PR |
| 13 | Agent mistake: `handout add 3000` with nothing listening | Publishes `https://s.example.test/<id>/` with a warning about exposure and absolute paths, exit 0. Nothing checks that the port answers | friction: see F4 |
| 14 | Agent mistake: `handout hits ffffff`, `handout rm ffffff` | `handout: no share with id 'ffffff'` | pass |
| 15 | User takes the link back: `handout rm <pasted link>` | `unpublished <id>`; the link answers 404 at once; `ls` no longer lists it | pass |

## Findings

| ID | Kind | Finding | Outcome |
|---|---|---|---|
| F1 | bug | `handout add <path that does not exist>` printed the usage line, so the person could not tell the path from the flags | Fixed: `bin/handout` `target_refusal`; section `add: a missing path is named` in `tests/share.sh`; proof `docs/verification/add-missing-path.md` |
| F2 | friction | `add` prints the link but not when it dies. The default is 30 days. A user who hands a client a link wants the date, and the agent has to run `ls` to learn it. The README example row said 7 days against a 30 day default | README row fixed. Printing the expiry is a CLI output change: filed below |
| F3 | friction | `hits` counts the user's own preview requests; there is no way to leave oneself out, so "4 hits" after three client opens and one self check reads as four opens | Not fixed, small: see `Not done` |
| F4 | friction | `add <port>` publishes a link to a port nobody listens on, then the client sees an error page | Not fixed: see `Not done` |

The ready `gh issue create` lines for F2 to F4 are in [README.md](README.md).
