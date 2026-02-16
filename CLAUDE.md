# CLAUDE.md — Project context for Claude Code

## What is hushbrew?

hushbrew is a macOS LaunchAgent that automatically upgrades Homebrew packages once daily. It's meeting-aware (skips during Zoom/Slack/mic-active), throttles download bandwidth to 60% of detected speed, and sends macOS notifications on completion or failure.

The project started as personal scripts at `~/.local/bin/brew-auto-upgrade.sh` and `~/.local/bin/brew-curl`, paired with a LaunchAgent plist. It was packaged into this repo for public distribution. Originally named "brew-auto-upgrade" — renamed to "hushbrew" because that name was already taken online.

## Repository layout

```
bin/
  hushbrew.sh                        Main upgrade script (434 lines, bash)
  brew-curl                          Curl wrapper that applies bandwidth rate limits (13 lines, no set -euo pipefail — uses exec)
launchd/
  com.local.hushbrew.plist           LaunchAgent template — uses __HOME__ placeholder
Formula/
  hushbrew.rb                        Homebrew formula for `brew install` support
install.sh                           Installer — copies files, generates plist, loads agent
uninstall.sh                         Uninstaller — unloads agent, removes files, preserves config
Makefile                             help / lint / install / uninstall targets
FORMULA_SETUP.md                     Guide for publishing as a Homebrew tap
TESTING_FORMULA.md                   Guide for testing the formula locally
.github/
  workflows/ci.yml                   ShellCheck on ubuntu + plist validation on macos
  ISSUE_TEMPLATE/bug_report.md       Bug report issue template
  ISSUE_TEMPLATE/feature_request.md  Feature request issue template
  PULL_REQUEST_TEMPLATE.md           PR checklist template
.claude/
  settings.json                      Permitted commands for Claude Code
  handoff.md                         Detailed thread context and current state for session handoff
.gitignore                           macOS artifacts, editor files, IDE dirs, Claude local state
.editorconfig                        Editor formatting rules
.shellcheckrc                        ShellCheck disabled rules (SC2086 intentional word-split, SC1090 dynamic source)
CLAUDE.md                            This file — project context for Claude Code
CHANGELOG.md                         Version history (currently 1.0.0)
CODE_OF_CONDUCT.md                   Contributor Covenant v2.1
CONTRIBUTING.md                      Contribution guidelines
SECURITY.md                          Security policy and config file sourcing warning
LICENSE                              MIT license (Copyright 2026 Sandeep Yadav)
README.md                            Full user-facing documentation with CI badges
```

## Architecture of the main script (`bin/hushbrew.sh`)

The script executes in this exact order:

1. **Brew prefix detection** (lines 24-36) — Checks `/opt/homebrew/bin/brew` first (Apple Silicon), then `/usr/local/bin/brew` (Intel), falls back to `brew --prefix`. Exits with error if brew not found.
2. **Log rotation** (lines 52-55) — If `~/.local/log/hushbrew.log` exceeds 1MB (`stat -f%z`, macOS/BSD syntax), rotates to `.log.old`.
3. **State check** (lines 57-60) — Reads `~/.local/log/hushbrew.lastrun`; exits immediately if already ran today (stores `YYYY-MM-DD`).
4. **Lock acquisition** (lines 62-67) — Uses `mkdir /tmp/hushbrew.lock` as an atomic lock. Trap removes it on exit.
5. **Brew process check** (lines 69-73) — `pgrep -f "$BREW_PREFIX/bin/brew"` to avoid clashing with a manual brew session.
6. **Config loading** (lines 79-87) — Sources `~/.config/hushbrew/config` if it exists. Currently only `EXCLUDED_FORMULAE` and `EXCLUDED_CASKS` (space-separated strings).
7. **Meeting detection** (lines 93-138) — Four sequential checks, short-circuits on first match:
   - `pgrep -x "CptHost"` — Zoom's meeting-host process (only exists during active call)
   - `lsof -c zoom.us -a -i UDP` — Zoom UDP audio streams
   - `lsof -c Slack -a -i UDP` excluding `:https` (port 443) — Slack WebRTC huddle traffic vs normal QUIC messaging
   - `ioreg -c AppleHDAEngineInput` checking `IOAudioEngineState = 1` — Microphone in use by any app
8. **Power status check** (lines 140-177) — Uses `pmset -g batt` to check power source and battery level. Skips if battery < 15% and not on AC power. Logs status and proceeds if on AC or battery >= 15%.
9. **Bandwidth detection** (lines 179-206) — Downloads 2MB from `speed.cloudflare.com`, measures `speed_download`, calculates 60% cap, floors at 1MB/s. Sets `BREW_RATE_LIMIT` env var.
10. **Environment setup** (lines 212-222) — Sets `PATH`, `HOMEBREW_NO_*` flags, and `HOMEBREW_CURL_PATH` to point at `brew-curl` wrapper.
11. **Helper functions** (lines 224-262) — Three helpers defined here, used by all subsequent steps:
    - `run_with_timeout SECS CMD...` — Wraps commands with `nice -n 15` and `timeout`. Requires GNU `timeout` from Homebrew `coreutils` (macOS does not ship `timeout` natively).
    - `filter_excluded ITEMS EXCLUSIONS` — Filters a space-separated list against an exclusion list (exact string match only).
    - `add_error MSG` — Appends to `step_errors` string (pipe-delimited) and logs as ERROR.
12. **Pre-flight checks** (lines 268-283) — Internet connectivity (curl formulae.brew.sh), disk space (1GB minimum on brew prefix volume).
13. **brew update** (lines 289-299) — 5 minute timeout, `nice -n 15`.
14. **Formula upgrade** (lines 305-322) — Lists outdated, filters exclusions, 15 minute timeout.
15. **Cask upgrade** (lines 328-357) — Same as formulae (15 minute timeout), plus warns about currently-running apps that may block cask upgrades.
16. **Cleanup** (line 363) — `brew cleanup --prune=7`, 5 minute timeout.
17. **Post-upgrade verification** (lines 375-413) — Checks for still-outdated formulae/casks (diagnoses pinned or running-app), broken deps (`brew missing`), disk space below 512MB.
18. **Notification + state write** (lines 419-431) — macOS notification via `osascript`, writes today's date to lastrun file. Only writes state on completion (not on early exits like blocked-by-meeting or no-internet, so the next scheduled slot retries).

## The brew-curl wrapper (`bin/brew-curl`)

Homebrew respects `HOMEBREW_CURL_PATH` to override its curl binary. `brew-curl` is a 13-line wrapper that uses `exec` to replace itself with `/usr/bin/curl`, passing `--limit-rate $BREW_RATE_LIMIT` if the env var is set. If `BREW_RATE_LIMIT` is unset, it passes through transparently. Note: `brew-curl` does NOT use `set -euo pipefail` because it `exec`s immediately — there is no error handling to do, the process is replaced.

## The plist template (`launchd/com.local.hushbrew.plist`)

Uses `__HOME__` as a literal placeholder string in the `<string>` value for `Program`. `install.sh` runs `sed "s|__HOME__|$HOME|g"` to generate the real plist. The schedule uses `StartCalendarInterval` with three entries: hours 10, 14, 18. Has `LowPriorityBackgroundIO`, `LowPriorityIO`, `ProcessType=Background`, and `Nice=15`.

## Key design decisions and rationale

- **Pure bash, no dependencies** — Only requires macOS + Homebrew. No Python, no Ruby, no npm. This is a conscious constraint — see CONTRIBUTING.md.
- **Portable brew prefix** — Detects `/opt/homebrew` (Apple Silicon) vs `/usr/local` (Intel) at runtime. All brew invocations use `$BREW` variable, never hardcoded paths.
- **External config via `source`** — `~/.config/hushbrew/config` is bash-sourced. Simple but has a security implication (arbitrary code execution) — documented in SECURITY.md.
- **LaunchAgent plist uses `__HOME__` placeholder** — Can't use `$HOME` in plists natively. `install.sh` does the substitution.
- **`mkdir` as lock** — Atomic on all filesystems, no race conditions, no stale PID files. Cleanup via EXIT trap.
- **Slack huddle detection excludes port 443** — Normal Slack uses QUIC (UDP 443) for messaging even when not in a huddle. Only non-443 UDP indicates an actual WebRTC huddle.
- **Power-aware with 15% threshold** — Uses `pmset` to check battery level. Skips upgrade if battery < 15% and not on AC. This prevents draining battery during critical work while still allowing upgrades when battery is sufficient.
- **Bandwidth floor of 1MB/s** — Prevents unusably slow downloads on poor connections where 60% would be too low.
- **`osascript` with `|| true`** — Notifications must never cause the script to fail. They're fire-and-forget.
- **SC2086 disabled in shellcheck** — Intentional word-splitting of `$formulae_to_upgrade` and `$casks_to_upgrade` to pass them as separate arguments to `brew upgrade`.

## Coding conventions

- Shell scripts use `set -euo pipefail` (exception: `brew-curl` does not, because it `exec`s immediately)
- All brew commands go through `$BREW` variable (never hardcoded paths)
- Log messages use the format: `YYYY-MM-DD HH:MM:SS | LEVEL: message` where LEVEL is one of: START, INFO, WARN, ERROR, SKIP, BLOCKED, ABORT, DONE, ISSUES
- Notifications use `osascript` with `|| true` to never fail the script
- All scripts must pass `shellcheck` (see `.shellcheckrc` for disabled rules)
- 4-space indentation, LF line endings (see `.editorconfig`)
- Section headers use double-line box-drawing characters: `═══`
- Sub-section headers use single-line: `── name ──`

## Testing

- Run `make lint` to check all scripts with shellcheck
- Run `make install` / `make uninstall` for local testing
- The CI workflow (`.github/workflows/ci.yml`) runs shellcheck on ubuntu-latest and plist validation on macos-latest
- Manual test: run `~/.local/bin/hushbrew.sh` directly and check `~/.local/log/hushbrew.log`

## Common tasks

- **Add a new meeting detection method**: Add a new numbered block in the "Meeting / Huddle Detection" section of `bin/hushbrew.sh`, following the existing pattern. Check `blocked_by` is empty first (`[ -z "$blocked_by" ]`), set `blocked_by="Description"` if detected.
- **Add a new config option**: Add the default value in the "Load Configuration" section (after the existing defaults), document it in `install.sh`'s default config heredoc, and mention it in `README.md` under Configuration.
- **Change the schedule**: Edit `launchd/com.local.hushbrew.plist` (the template). Users who already installed need to re-run `install.sh` or manually reload.
- **Add a new pre-flight check**: Add in the "Pre-flight Checks" section. Exit 0 without writing state file so the next scheduled slot can retry.

## Installation methods

**Two installation paths:**

1. **Homebrew Formula (Recommended)** — `Formula/hushbrew.rb`
   - Users: `brew install YOUR_USERNAME/hushbrew/hushbrew`
   - Formula handles everything in `post_install` (creates dirs, copies scripts, generates plist)
   - Uses `brew services start hushbrew` to load LaunchAgent
   - Installs to same locations as manual install (`~/.local/bin`, etc.)
   - Depends on `coreutils` (for GNU timeout)

2. **Manual Installation** — `install.sh` script
   - Users: `git clone && ./install.sh`
   - Direct bash script, no Homebrew formula involved
   - Same result as formula method

Both methods produce identical installations. The formula just provides a better UX.

## Homebrew formula structure

`Formula/hushbrew.rb` is a Ruby file following Homebrew conventions:
- `install` method: Copies files to `libexec` (Homebrew's internal storage)
- `post_install` method: Does the actual setup (creates dirs, installs to `~/.local/bin`, generates plist)
- `caveats` method: Shows post-install instructions to user
- `service` block: Defines how `brew services` interacts with the LaunchAgent
- `test` block: Validates installation (syntax checks, file existence)

**Why `post_install`?** Homebrew typically installs to its own prefix (`/opt/homebrew` or `/usr/local`), but hushbrew uses `~/.local/bin` and `~/.config/hushbrew` for user-specific locations. `post_install` runs after the main install and can write to user directories.

**Before publishing:** Update placeholders in `Formula/hushbrew.rb`:
- Replace `YOUR_USERNAME` with GitHub username
- Replace `YOUR_SHA256_CHECKSUM_HERE` with actual sha256 of release tarball
- Create a git tag: `git tag v1.0.0 && git push origin v1.0.0`

See `FORMULA_SETUP.md` for full publishing instructions and `TESTING_FORMULA.md` for local testing.

## Files that reference each other (dependency map)

- `install.sh` reads from: `bin/hushbrew.sh`, `bin/brew-curl`, `launchd/com.local.hushbrew.plist`
- `install.sh` writes to: `~/.local/bin/hushbrew.sh`, `~/.local/bin/brew-curl`, `~/.config/hushbrew/config`, `~/Library/LaunchAgents/com.local.hushbrew.plist`
- `Formula/hushbrew.rb` reads from: `bin/hushbrew.sh`, `bin/brew-curl`, `launchd/com.local.hushbrew.plist`
- `Formula/hushbrew.rb` writes to: Same locations as `install.sh` (in `post_install` method)
- `uninstall.sh` removes: everything `install.sh` writes (except config dir — kept by default)
- `bin/hushbrew.sh` reads: `~/.config/hushbrew/config`, `~/.local/log/hushbrew.lastrun`
- `bin/hushbrew.sh` writes: `~/.local/log/hushbrew.log`, `~/.local/log/hushbrew.lastrun`
- `bin/hushbrew.sh` sets: `HOMEBREW_CURL_PATH=$HOME/.local/bin/brew-curl` (tells brew to use the wrapper)
- `Makefile` calls: `shellcheck` on all 4 scripts, `./install.sh`, `./uninstall.sh`
- `.github/workflows/ci.yml` runs: `shellcheck` on all 4 scripts, `plutil -lint` on the plist
