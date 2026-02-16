# Changelog

All notable changes to hushbrew will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
