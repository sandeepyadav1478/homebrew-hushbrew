# Contributing to hushbrew

Thanks for your interest in improving hushbrew! Here's how to contribute.

## Getting started

1. Fork the repo and clone your fork
2. Make your changes on a feature branch
3. Run `make lint` to ensure scripts pass shellcheck
4. Test locally with `make install`, verify the log, then `make uninstall`
5. Open a pull request

## Guidelines

- **Keep it simple** — hushbrew is intentionally a single bash script with no dependencies beyond macOS and Homebrew.
- **No new runtime dependencies** — Don't add Python, Node, Ruby, or anything else. Pure bash + standard macOS tools.
- **Test on both architectures if possible** — Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`). If you only have one, mention it in your PR.
- **Pass shellcheck** — Run `make lint` before submitting. The CI will check this too.
- **Update docs** — If you change behavior, update README.md and CHANGELOG.md.

## What to work on

- Check [open issues](../../issues) for bugs and feature requests
- Meeting detection for new apps is always welcome (Teams, WebEx, etc.)
- Improvements to bandwidth detection
- Better notification support

## Code style

- `set -euo pipefail` at the top of every script
- 4-space indentation (no tabs in shell scripts)
- Use `$BREW` variable, never hardcode brew paths
- Log format: `YYYY-MM-DD HH:MM:SS | LEVEL: message`
- Comments explain *why*, not *what*

## Reporting bugs

Open an issue with:
- Your macOS version and chip (Apple Silicon / Intel)
- The relevant log lines from `~/.local/log/hushbrew.log`
- Steps to reproduce if possible
