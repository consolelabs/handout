# Mega-goal: multi-member tenants

Destination: SPEC-010 groundwork, then SPEC-009 phase by phase, ending with a live member on s.console.so.
Specs: `docs/specs/SPEC-010-state-groundwork.md`, `docs/specs/SPEC-009-multi-member.md` (both VALIDATED, owner decisions D1 to D5 and D7 applied).
Run config: merge_autonomy full-auto (owner: "auto approve till the end", 2026-11-14), MEGA_MERGE_POSTURE auto-to-final, WAVE_CAP 2.
Terminus: deployable. Sub-goal 12 is the live acceptance on a real tenant; the owner pre-approved it. No release tag is cut inside this mega-goal (D10).
Done = a box is `[x]` only with `-- PR #<n>` of a merged PR.
The sub-goal files for the re-cut rows SG-13 to SG-20 are not on main yet; only `goals/01` to `goals/12` are.

- [x] SG-01 Live samples on Console Labs (SPEC-009 TASK-1a) , auto , depends none -- PR #52 (OQ-7 stays open: R2 off on Console Labs, live leg owed by SG-11)
- [x] SG-02 State groundwork must (SPEC-010 G1 G1b G2a G2b G2c G3 G4 G5 G13) , auto , depends none -- PR #54
- [x] SG-03 Caddy listed rows and Worker v5 (SPEC-009 TASK-0a to 0f) , auto , depends SG-02 -- PR #55
- [x] SG-04 State groundwork should, bash (SPEC-010 G6 G7 G8 G9 G10 G14) , auto , depends SG-03 -- PR #56
- [x] SG-05 Members core (SPEC-009 TASK-1b to 1i) , auto , depends SG-04 SG-01 -- PR #57
- [x] SG-06 Share Bar foundations (SPEC-010 G11a G11b G11c, SPEC-009 TASK-4b1 to 4b5) , auto , depends SG-04 -- PR #61
- [x] SG-07 Revoke, reconcile, rm, purge, leave (SPEC-009 TASK-2a to 2e) , auto , depends SG-05 -- PR #62
- [x] SG-13 Fast test loop: section filter, section timing, idle waits , auto , depends SG-07 -- PR #64
- [x] SG-18 Spec gaps from the audit trace (dead setup-r2 guard, 401 on add, join step 2 split) , auto , depends SG-13 -- PR #74
- [x] SG-19 CI shards for the bash suite (6 Ubuntu, up to 5 macOS) , auto , depends SG-13 -- PR #67
- [x] SG-11 Member docs as specced (SPEC-009 TASK-4c, without the suite docs grep) , auto , depends SG-07 -- PR #63
- [x] SG-08 Pause, resume, invite, rotate, renew (SPEC-009 TASK-3a to 3d) , auto , depends SG-18 -- PR #75
- [x] SG-14 Adopt, WebSocket through a binding, min_cli (SPEC-009 TASK-3e, 3f, 4a) , auto , depends SG-08 -- PR #77
- [x] SG-09 Share Bar popover A: shell, list, issues, row actions (SPEC-009 TASK-4b6 to 4b9) , auto , depends SG-06 -- PR #65
- [x] SG-20 Popover design parity: window surface, placeholder, keycap, row menu anchor, row age, separator , auto , depends SG-09 -- PR #66
- [x] SG-15 Share Bar popover B: publish and drop, drag out, Quick Look, hotkey (SPEC-009 TASK-4b10 to 4b13) , auto , depends SG-20 -- PR #69
- [x] SG-10 Share Bar settings A: General, Advanced, dialogs, Tenants, journaled flows (SPEC-009 TASK-4b14 to 4b18) , auto , depends SG-09 -- PR #68
- [x] SG-16 Share Bar settings B: Members, All links, app states, keyboard and VoiceOver, errors (SPEC-009 TASK-4b19 to 4b23) , auto , depends SG-15 SG-10 -- PR #76
- [ ] SG-17 Live e2e suite and the docs grep (SPEC-009 TASK-4d, TASK-4c grep) , auto , depends SG-14 SG-16 SG-11 -- not done: the docs grep half (tests/share.sh "tenant docs" section, and the re-check of the member docs against the built verbs) landed in PR #78; tests/e2e-members.sh and the live ML-1 to ML-12 and OQ-7 legs are still open and need R2 on the Console Labs account
- [ ] SG-12 Live acceptance on s.console.so (SPEC-009 TASK-4e) , auto , depends SG-17 -- parked: blocked on Cloudflare R2 for Console Labs (an owner task: enable R2 and grant the admin token an R2 permission group), plus SG-17
