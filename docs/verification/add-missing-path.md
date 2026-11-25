# Proof of done: add-missing-path

Date: 2026-11-25. Branch: `docs/rehearsal-rounds`.

Change: `handout add <path that does not exist>` printed the usage line, the same one it prints for a bad flag. It now prints `handout: no such file or folder: <path>; nothing was published`. A port shape that does not parse (`localhost:abc`) and an add with no target keep the usage line. Found in product rehearsal round 1 (`docs/product/rehearsal/01-agent-report.md`, step 12).

## Recorded run

```
Command: SHARE_TEST_PORT_BASE=43100 SHARE_TEST_ONLY='^add: a missing path' bash tests/share.sh
Exit: 0
Output: 18 checks, PASS (filtered by SHARE_TEST_ONLY: 1 sections ran, the rest skipped)
Verdict: PASS

Command: /bin/bash -n bin/handout && /bin/bash -n install.sh && shellcheck bin/handout install.sh
Exit: 0
Output: parse-ok, shellcheck-ok (no output)
Verdict: PASS

Command: bash tests/ci/shard-check.sh
Exit: 0
Output: shard-check: 87 sections, 3 shards, each section in exactly one
Verdict: PASS
```

The 18 checks are the section's 4 rows plus the suite's own isolation checks (no real launchd or systemd job, no real Keychain item, no stray server).

Not run: the full suite and the other shards. The change is two call sites of one helper in `cmd_add`, and no other row greps the usage line of `add` for a missing path (`rg 'usage: handout add' tests` finds one row, for `--cloud --local`).

## Negative control

The change is committed, then `bin/handout` is put back to `origin/main`.

```
Command: git checkout origin/main -- bin/handout; SHARE_TEST_PORT_BASE=43100 SHARE_TEST_ONLY='^add: a missing path' bash tests/share.sh
Exit: 1
Output:
  FAIL  add of a path that is not there says so, once, and not the usage line: expected '1|1|0', got '1|0|1'
  FAIL  the same under --cloud, which settles the storage first: expected '1|1|0', got '1|0|1'
  2/18 FAILED
Verdict: RED as expected. The two rows catch the old behavior (no "no such file" line, one "usage:" line); the two rows for the shapes that must keep the usage line stay green.

Command: git checkout HEAD -- bin/handout; the same filter
Exit: 0
Output: 18 checks, PASS (filtered by SHARE_TEST_ONLY: 1 sections ran, the rest skipped)
Verdict: PASS, restored
```
