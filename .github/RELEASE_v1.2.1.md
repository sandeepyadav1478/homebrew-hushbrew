## 🐛 Bug Fixes: Leaves Mode & Cask Timeout

This patch release fixes 3 real-world issues discovered from production logs.

### Issues Fixed

#### 1. Leaves Mode Silently Skipping All Formulae
`brew leaves` was called without a timeout. When it hung or returned empty (due to network issues), hushbrew silently skipped **all** formulae — showing "No formulae to upgrade" even with 19 outdated packages.

**Fix:** Added 60s timeout to `brew leaves`. If it times out or returns empty, hushbrew now logs a warning and falls back to `all` strategy automatically.

```
WARN: brew leaves returned empty or timed out — falling back to all strategy
```

#### 2. `UPGRADE_STRATEGY` Left as `leaves` After Testing
Packages like `llvm`, `node`, `grpc`, `apache-arrow` are installed as dependencies (not leaves), so they were never upgraded in leaves mode — causing persistent "WITH ISSUES" notifications.

**Fix:** The fallback behaviour in fix #1 ensures this can't silently cause missed upgrades.

#### 3. Cask Upgrade Timeout Too Short
Large casks like `claude-code` and `postman` were being killed with `SIGTERM` during download at throttled speeds (1.4 MB/s), hitting the old 15-minute limit.

**Fix:** Increased cask upgrade timeout from **15 minutes → 30 minutes**.

---

### Upgrade Instructions

```bash
brew update
brew upgrade hushbrew
hushbrew version  # Should show v1.2.1
```

---

### 🙏 Feedback

Report bugs or suggest features via [Issues](https://github.com/sandeepyadav1478/homebrew-hushbrew/issues)
