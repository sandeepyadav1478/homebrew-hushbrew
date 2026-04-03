# Changelog

All notable changes to hushbrew will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.2.4] - 2026-04-03

### Fixed
- Daily failure notifications caused by msodbcsql18 interactive license prompt — added `HOMEBREW_ACCEPT_EULA=Y` to non-interactive environment
- Post-upgrade verification reporting false positives for packages that weren't targeted for upgrade
- docker-desktop cask failing due to sudo requirement — added to default exclusion list

## [1.2.3] - 2026-03-02

### Fixed
- Cleaned up confusing post-install messages

## [1.2.2] - 2026-03-02

### Fixed
- `hushbrew start` crashing when service is already running

## [1.2.1] - 2026-03-02

### Fixed
- Leaves mode hanging when `brew leaves` takes too long (added 60s timeout with fallback to full strategy)
- Cask upgrade timeout increased from 15 min to 30 min for large app downloads

## [1.2.0] - 2026-02-17

### Added
- Leaves-only upgrade strategy (`UPGRADE_STRATEGY="leaves"` in config)
- Only upgrades top-level packages; dependencies update only when needed

## [1.1.0] - 2026-02-17

### Added
- Comprehensive CLI command suite: `hushbrew start`, `stop`, `status`, `logs`, `run`, `config`, `version`, `help`
- Power-aware upgrades — skips if battery < 15% and not on AC power

## [1.0.4] - 2026-02-16

### Changed
- `hushbrew stop` now fully removes all installed files (clean uninstall)
- Repository renamed from `brew-auto-upgrade` to `homebrew-hushbrew`

## [1.0.3] - 2026-02-16

### Fixed
- Graceful error handling for brew commands
- LaunchAgent scheduling reliability

## [1.0.2] - 2026-02-16

### Changed
- Simplified to 2 commands: `install` and `start`

## [1.0.1] - 2026-02-16

### Added
- Setup script (`hushbrew-setup`) to avoid Homebrew sandbox issues during post-install

## [1.0.0] - 2026-02-16

### Added
- Initial release
- Automatic daily Homebrew upgrades via LaunchAgent
- Meeting detection: Zoom (CptHost process + UDP audio), Slack huddles (WebRTC), microphone-in-use (IOAudioEngine)
- Bandwidth throttling: measures speed via Cloudflare, caps brew downloads at 60%
- Custom curl wrapper (`brew-curl`) for rate limiting
- External config file (`~/.config/hushbrew/config`) for exclusion lists
- Portable Homebrew prefix detection (Apple Silicon + Intel)
- Pre-flight checks: internet connectivity, disk space (1 GB minimum)
- Post-upgrade verification: outdated packages, broken dependencies, disk space
- macOS notifications for all status changes
- Log rotation at 1 MB
- Lock file to prevent concurrent runs
- Timeout protection (5 min for update, 15 min for upgrades)
- Low-priority execution (`nice`, `LowPriorityBackgroundIO`)
- Retry schedule: 10 AM, 2 PM, 6 PM
- Installer and uninstaller scripts
- ShellCheck CI via GitHub Actions
- Plist XML validation in CI
