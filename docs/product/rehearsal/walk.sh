#!/bin/bash
# walk.sh: the dry legs of the product rehearsal walks in this folder. It runs the real CLI against the
# suite's isolation (throwaway root, config and HOME, stubbed launchctl, systemctl, security and op) and
# against the dry seams (SHARE_R2_DRY, SHARE_ACCESS_DRY, SHARE_TUNNEL=0): no Cloudflare account, no DNS,
# no live host, no message to anyone. It prints every command and what came back, so a walk record can
# quote it.
#
# Usage: docs/product/rehearsal/walk.sh [j1] [j2] [j3]     (default: all)
#   j1  an agent builds a report, publishes it, the user sends the link to a client
#   j2  an admin invites a member, the member joins and publishes
#   j3  daily use: the calls Handout Bar makes for a drag to publish, a copied link and a visitor check
# The app's own screens (popover, row menu, drop target) run through its test hooks in the mac-ui VM, not here.
set -uo pipefail

SH="$(cd "$(dirname "$0")/../../.." && pwd)/bin/handout"
W="$(mktemp -d)"
BASE="${REHEARSAL_PORT_BASE:-41200}"
( sleep "${REHEARSAL_WATCHDOG:-1200}"; echo "walk.sh: watchdog fired" >&2; kill -TERM $$ ) 2>/dev/null &
WATCH=$!
cleanup() {
  kill "$WATCH" 2>/dev/null
  HOME="$W/j1/home" SHARE_ROOT="$W/j1/root" SHARE_CONFIG_DIR="$W/j1/config" SHARE_PORT=$((BASE + 1)) SHARE_SERVICE_LABEL="rehearsal-$$" bash "$SH" stop >/dev/null 2>&1 || true
  HOME="$W/mx/member" bash "$SH" stop >/dev/null 2>&1 || true
}
trap cleanup EXIT

step() { printf '\n### %s\n' "$*"; }
note() { printf '(%s)\n' "$*"; }
show() { printf '$ %s\n' "$*"; }
# run <cmd...>: print the command, its stdout and stderr merged, and its exit code
run() { show "$*"; "$@" 2>&1; local rc=$?; echo "[exit $rc]"; return 0; }

# Stubs the suite uses: no launchd or systemd job, an empty Keychain, a signed-out 1Password.
STUBS="$W/stubs"; mkdir -p "$STUBS"
printf '#!/bin/bash\n[[ $1 == print ]] && exit 1\nexit 0\n' >"$STUBS/launchctl"
printf '#!/bin/bash\nexit 0\n' >"$STUBS/systemctl"
cat >"$STUBS/security" <<'SEC'
#!/bin/bash
[[ $1 == find-* || $1 == delete-* ]] && exit 44
exit 0
SEC
printf '#!/bin/bash\necho "op: signed out" >&2\nexit 1\n' >"$STUBS/op"
chmod +x "$STUBS"/*
unset XDG_CONFIG_HOME   # `profiles` lists the profile folders under it, whatever SHARE_CONFIG_DIR says
export PATH="$STUBS:$PATH"   # every call below, the member and admin helpers included, sees the stubs first

echo "# environment"
for t in bash caddy cloudflared jq node pandoc curl; do
  printf '%s: %s\n' "$t" "$(command -v "$t" || echo missing)"
done
echo "bash $BASH_VERSION; handout $(bash "$SH" version)"

# ---------------------------------------------------------------- j1
j1() {
  local J="$W/j1" P=$((BASE + 1)) h; h="$(hostname -s)"
  mkdir -p "$J/root" "$J/config" "$J/work" "$J/home"
  # hand: the default profile of a machine whose hostname is s.example.test (what the suite does in place of setup)
  hand() {
    env HOME="$J/home" PATH="$STUBS:$PATH" SHARE_ROOT="$J/root" SHARE_CONFIG_DIR="$J/config" SHARE_PORT="$P" SHARE_TUNNEL=0 SHARE_CLIPBOARD=0 \
      SHARE_HOSTNAME=s.example.test SHARE_SERVICE_LABEL="rehearsal-$$" SHARE_HOSTS="$h" SHARE_ERROR_JSON="${EJ:-0}" bash "$SH" "$@"
  }
  # cold: the same machine before any setup
  cold() {
    env -u SHARE_HOSTNAME HOME="$J/home" PATH="$STUBS:$PATH" SHARE_ROOT="$J/cold/root" SHARE_CONFIG_DIR="$J/cold/config" SHARE_PORT="$((BASE + 2))" SHARE_TUNNEL=0 SHARE_CLIPBOARD=0 \
      SHARE_SERVICE_LABEL="rehearsal-cold-$$" SHARE_HOSTS="$h" bash "$SH" "$@"
  }
  visit() { # visit <ip> <path>: a client opening the link; the edge sets Cf-Connecting-Ip
    curl -s -o /dev/null -w '%{http_code}' -H "Host: s.example.test" -H "Cf-Connecting-Ip: $1" "http://127.0.0.1:$P$2"
  }

  echo; echo "# JOURNEY 1: an agent builds a report, publishes it, the user sends the link to a client"

  printf '%s\n' '<!doctype html><title>Q4 report</title><h1>Q4 report</h1><p>Revenue up 12 percent.</p>' >"$J/work/report.html"
  step "1.1 first contact: the agent finds a machine where Handout is installed but not set up"
  run cold state
  run cold add "$J/work/report.html"

  step "1.2 the user installs the agent skill (what a coding agent reads)"
  run env HOME="$J/home" bash "$SH" skill --install
  note "SKILL.md lines: $(wc -l <"$J/home/.claude/skills/handout/SKILL.md")"

  step "1.3 the agent reads state before publishing (the skill says to)"
  run hand state

  step "1.4 the agent builds the report"
  cat >"$J/work/report.html" <<'HTML'
<!doctype html><title>Q4 report</title><h1>Q4 report</h1><p>Revenue up 12 percent.</p>
HTML
  note "wrote $J/work/report.html"

  step "1.5 the agent publishes it"
  local out; show "handout add report.html"
  out="$(hand add "$J/work/report.html" 2>&1)"; echo "$out"
  local url id; url="$(grep -m1 '^https://' <<<"$out")"; id="$(cut -d/ -f4 <<<"$url")"
  note "link: $url ; id: $id"

  step "1.6 the client opens the link (the local server stands in for the edge)"
  show "GET the link as 203.0.113.7 twice, then as 198.51.100.9"
  echo "status: $(visit 203.0.113.7 "/$id/report.html") $(visit 203.0.113.7 "/$id/report.html") $(visit 198.51.100.9 "/$id/report.html")"
  show "GET the site root, a wrong id, a dotfile path"
  echo "status: $(visit 203.0.113.7 /) $(visit 203.0.113.7 /ffffff/report.html) $(visit 203.0.113.7 "/$id/.env")"
  note "body the client sees: $(curl -s -H 'Host: s.example.test' "http://127.0.0.1:$P/$id/report.html" | head -c 200)"
  sleep 1

  step "1.7 the user asks: did the client open it?"
  run hand hits "$id"
  run hand hits "$url"
  run hand ls
  run hand status

  step "1.8 the agent revises the report, the user wants the same link"
  echo '<!doctype html><title>Q4 report</title><h1>Q4 report</h1><p>Revenue up 12 percent. Costs flat.</p>' >"$J/work/report.html"
  run hand refresh "$id"
  note "client sees: $(curl -s -H 'Host: s.example.test' "http://127.0.0.1:$P/$id/report.html" | head -c 200)"

  step "1.9 the client should not forward it: the agent tries a private link with no token set"
  EJ=1 run hand add "$J/work/report.html" --access email:client@example.com

  step "1.10 the agent publishes a markdown report and a folder"
  printf '# Notes\n\nSome findings.\n' >"$J/work/notes.md"
  mkdir -p "$J/work/pack/img"; echo '<h1>pack</h1>' >"$J/work/pack/index.html"; echo secret >"$J/work/pack/.env"
  run hand add "$J/work/notes.md"
  run hand add --ttl 3d "$J/work/pack"

  step "1.11 mistakes an agent makes"
  run hand add "$J/work/missing.pdf"
  run hand add 3000
  run hand add "$J/work/.hidden"
  run hand hits ffffff
  run hand rm ffffff

  step "1.12 the user takes the link back"
  run hand rm "$url"
  echo "status after rm: $(visit 203.0.113.7 "/$id/report.html")"
  run hand ls
  hand stop >/dev/null 2>&1
}

# ---------------------------------------------------------------- j2
MX="$W/mx"
MXH="$MX/home"; MXD="$MX/bucket"; MXM="$MX/member"
mx_this="$(hostname -s)"
mx_setup_fixtures() {
  mkdir -p "$MX/bin" "$MX/kv"
  cat >"$MX/bin/security" <<EOF
#!/bin/bash
kv="\${MX_KV:-$MX/kv}"; mkdir -p "\$kv"
svc=""; val=""; prev=""; for a in "\$@"; do case \$prev in -s) svc="\$a" ;; -w) val="\$a" ;; esac; prev="\$a"; done
case \$1 in
  -i) line="\$(cat)"; svc="\$(sed -n 's/.* -s "\\([^"]*\\)".*/\\1/p' <<<"\$line")"; val="\$(sed -n 's/.* -w "\\([^"]*\\)".*/\\1/p' <<<"\$line")"; [[ -n \$svc ]] && printf '%s' "\$val" >"\$kv/\$svc"; exit 0 ;;
  add-generic-password) printf '%s' "\$val" >"\$kv/\$svc"; exit 0 ;;
  find-generic-password) [[ -f "\$kv/\$svc" ]] || exit 44; [[ " \$* " == *" -w "* ]] && cat "\$kv/\$svc"; exit 0 ;;
  delete-generic-password) rm -f "\$kv/\$svc"; exit 0 ;;
esac
exit 0
EOF
  printf '#!/bin/bash\nmkdir -p "%s/trashed"; mv -f "$1" "%s/trashed/$(basename "$1").$$.$RANDOM"\n' "$MX" "$MX" >"$MX/bin/trash"
  printf '#!/bin/bash\nexit 0\n' >"$MX/bin/cloudflared"
  chmod +x "$MX/bin/security" "$MX/bin/trash" "$MX/bin/cloudflared"
}
mxa() { # the admin's machine: the origin profile ten of mx.example.test, R2 and Access dry
  local e=(env -u SHARE_ROOT -u SHARE_CONFIG_DIR -u SHARE_PORT -u SHARE_HOSTNAME -u XDG_CONFIG_HOME -u SHARE_PROFILE -u SHARE_BACKEND -u CLOUDFLARE_API_TOKEN -u SHARE_MINTER_TOKEN
    HOME="$MXH" PATH="$MX/bin:$PATH" SHARE_TUNNEL=0 SHARE_R2_DRY=1 SHARE_R2_DRY_DIR="$MXD" SHARE_R2_TOKEN=drytoken SHARE_ACCESS_DRY=1 SHARE_ACCESS_POLL=0
    SHARE_R2_WAIT=2 SHARE_HOSTS="$mx_this" SHARE_LEASE_WAIT=2 SHARE_ERROR_JSON="${EJ:-0}")
  [[ ${MX_TOK:-} == - ]] || e+=(CLOUDFLARE_API_TOKEN="${MX_TOK:-admintoken}")
  [[ ${MX_MINT:-} == - ]] || e+=(SHARE_MINTER_TOKEN="${MX_MINT:-mintertoken}")
  "${e[@]}" bash "$SH" --profile ten "$@"
}
mxm() { # the member's Mac: its own HOME, the default profile, the same dry bucket and a dry Worker that reads it
  env -u SHARE_ROOT -u SHARE_CONFIG_DIR -u SHARE_PORT -u SHARE_HOSTNAME -u XDG_CONFIG_HOME -u SHARE_PROFILE -u SHARE_BACKEND -u CLOUDFLARE_API_TOKEN -u SHARE_MINTER_TOKEN -u SHARE_HOSTS \
    HOME="$MXM" MX_KV="$MX/kv-member" PATH="$MX/bin:$PATH" SHARE_TUNNEL=0 SHARE_JOIN_SERVICE=0 SHARE_CLIPBOARD=0 SHARE_R2_DRY=1 SHARE_R2_DRY_DIR="$MXD" SHARE_R2_WAIT=2 SHARE_ERROR_JSON="${EJ:-0}" \
    SHARE_R2_DRY_WORKER="node $(dirname "$SH")/../tests/worker.mjs --dir $MXD --host mx.example.test" bash "$SH" "$@"
}
j2() {
  local MP=$((BASE + 30)) AP=$((BASE + 20)) out code
  mx_setup_fixtures
  mkdir -p "$MXH/.config/share/profiles/ten" "$MXH/share/profiles/ten/pub" "$MXD/.cf" "$MXM" "$MX/work"
  printf 'hostname=mx.example.test\ntunnel_id=tid-mx\ntunnel_name=share-mx-example-test\nauth=api\nhosts=%s\nport=%s\n' "$mx_this" "$AP" >"$MXH/.config/share/profiles/ten/config"
  : >"$MXD/.cf/bucket"; printf '{"v":1,"host":"mx.example.test"}\n' >"$MXD/share.json"
  echo; echo "# JOURNEY 2: an admin invites a member, the member joins and publishes"
  note "the admin's tenant is a tunnel origin that already ran setup; R2 and members are the steps a team admin takes next"

  step "2.1 admin: turn R2 on at the origin"
  run mxa setup mx.example.test --r2 --bucket mx-bucket

  step "2.2 admin: turn members on"
  run mxa setup mx.example.test --r2 --bucket mx-bucket --members --yes

  step "2.3 admin invites a machine member, but the minter token is not set"
  EJ=1 MX_MINT=- run mxa member add ana --machine --port "$MP"

  step "2.4 admin invites a machine member"
  show "handout member add ana --machine --port $MP"
  out="$(mxa member add ana --machine --port "$MP" 2>&1)"; echo "$out"
  code="$(sed -n 's/^handout join [^ ]* \([^ ]*\)$/\1/p' <<<"$out" | head -1)"
  note "code length: ${#code}"
  run mxa member ls

  step "2.5 member: a wrong code, then the right one"
  run mxm join mx.example.test AAAAAAAAAAAAAAAAAAAA
  show "handout join mx.example.test <code>"
  out="$(mxm join mx.example.test "$code" 2>&1)"; echo "$out"

  step "2.6 member: the same code again (someone forwarded the message)"
  run mxm join mx.example.test "$code"

  step "2.7 member: status, then publish"
  run mxm status
  printf 'Q4 numbers\n' >"$MX/work/report.txt"
  show "handout add report.txt"
  out="$(mxm add "$MX/work/report.txt" 2>&1)"; echo "$out"
  local url id; url="$(grep -m1 '^https://' <<<"$out")"; id="$(cut -d/ -f4 <<<"$url")"
  run mxm ls
  run mxm hits "$id"

  step "2.8 a visitor opens the member's link through the Worker (dry Worker, the member's Caddy)"
  local bind; bind="$(jq -r '[.bindings[] | select(.name | test("^M_")) | .name] | first' "$MXD/.cf/script.json" 2>/dev/null)"
  note "binding: $bind"
  node "$(dirname "$SH")/../tests/worker.mjs" --dir "$MXD" --host mx.example.test --bind "$bind=127.0.0.1:$MP" "/$id/report.txt" 2>&1 | head -8

  step "2.9 admin: sees the member and its link"
  run mxa ls
  run mxa member ls
  run mxa status

  step "2.10 admin pauses the member, then resumes"
  run mxa member pause ana
  note "visitor now: $(node "$(dirname "$SH")/../tests/worker.mjs" --dir "$MXD" --host mx.example.test --bind "$bind=127.0.0.1:$MP" "/$id/report.txt" 2>&1 | awk '/^[0-9]{3} \// {print $1}')"
  run mxa member resume ana

  step "2.11 member leaves"
  run mxm leave
  mxm stop >/dev/null 2>&1
}

j3() {
  local J="$W/j3" P=$((BASE + 3)) h; h="$(hostname -s)"
  mkdir -p "$J/root" "$J/config" "$J/work" "$J/home"
  hand() {
    env HOME="$J/home" SHARE_ROOT="$J/root" SHARE_CONFIG_DIR="$J/config" SHARE_PORT="$P" SHARE_TUNNEL=0 SHARE_CLIPBOARD=0 \
      SHARE_HOSTNAME=s.example.test SHARE_SERVICE_LABEL="rehearsal3-$$" SHARE_HOSTS="$h" bash "$SH" "$@"
  }
  echo; echo "# JOURNEY 3: daily use of Handout Bar, as the CLI calls it makes"
  step "3.1 drag to publish: the app runs 'add <path>' with SHARE_PROGRESS=1 and reads the progress lines (the popover's progress row)"
  printf 'Q4 plan\n' >"$J/work/Q4-plan.pdf"
  show "SHARE_PROGRESS=1 handout --profile default add Q4-plan.pdf"
  SHARE_PROGRESS=1 hand --profile default add "$J/work/Q4-plan.pdf" 2>&1
  step "3.2 the popover reads one state call; a row carries what Copy link, the badges and the menu need"
  show "handout state | jq '.shares[0]'"
  hand state | jq '.shares[0]'
  local url id; url="$(hand state | jq -r '.shares[0].url')"; id="$(cut -d/ -f4 <<<"$url")"
  note "Copy link puts this url on the clipboard: $url"
  step "3.3 a visitor opens it twice; the user wants to know"
  curl -s -o /dev/null -H "Host: s.example.test" -H "Cf-Connecting-Ip: 203.0.113.7" "http://127.0.0.1:$P/$id/Q4-plan.pdf"
  curl -s -o /dev/null -H "Host: s.example.test" -H "Cf-Connecting-Ip: 203.0.113.7" "http://127.0.0.1:$P/$id/Q4-plan.pdf"
  sleep 1
  run hand hits "$id"
  note "state carries no hit count: $(hand state | jq -c '.shares[0] | keys')"
  step "3.4 profiles --json, the one read the popover refreshes from"
  show "handout profiles --json | jq -c '{schema, profiles: [name, state, share count]}'"
  hand profiles --json | jq -c '{schema, profiles: [.profiles[] | {name, state: .state.state, shares: (.state.shares | length)}]}'
  hand stop >/dev/null 2>&1
}

want=("$@"); [[ ${#want[@]} -gt 0 ]] || want=(j1 j2 j3)
for j in "${want[@]}"; do "$j"; done
echo; echo "# walk.sh done"
