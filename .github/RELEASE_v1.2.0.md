## 🎯 New Feature: Leaves-Only Upgrade Strategy

Control upgrade scope with a new configuration option!

### What's New

**Upgrade Strategy Configuration:**
```bash
hushbrew config set upgrade-strategy leaves  # Only upgrade top-level packages
hushbrew config set upgrade-strategy all     # Upgrade everything (default)
```

**What It Does:**
- `all` mode (default): Upgrades all outdated packages
- `leaves` mode: Only upgrades packages YOU explicitly installed
  - Skips dependencies of unused/orphaned packages
  - Dependencies still upgrade when needed by active leaves
  - Smaller upgrade scope = better control

### Example

```bash
# Your leaves: node, python, git
# Dependencies: openssl, icu4c (from node)

# With upgrade-strategy="leaves":
# Upgrades: node, python, git
# Skips: orphaned dependencies
# Updates: dependencies when leaves need them
```

### 📦 Upgrade Instructions

```bash
brew update
brew upgrade hushbrew
hushbrew version  # Should show v1.2.0
```

### Full Feature List

All v1.1.0 features plus leaves-only mode:
- Config management (show, edit, set)
- Exclusion management (add, remove, list)
- Schedule management (view, modify)
- Enhanced logs (--clear, --last)
- Test command (validate environment)
- Dry-run command (preview upgrades)
- **NEW:** Leaves-only upgrade strategy

### 🔧 Technical Details

**Configuration File:** `~/.config/hushbrew/config`

Add this line to enable leaves-only mode:
```bash
UPGRADE_STRATEGY="leaves"
```

Or use the command:
```bash
hushbrew config set upgrade-strategy leaves
```

**How It Works:**
1. Gets list of outdated packages: `brew outdated --formula`
2. Gets your installed packages: `brew leaves`
3. Filters outdated to only include leaves
4. Runs: `brew upgrade node python git` (only your packages)
5. Homebrew automatically upgrades their dependencies if needed

**Benefits:**
- Smaller blast radius (fewer packages = easier debugging)
- Skip orphaned dependencies (old tools you don't use anymore)
- Better control over what gets upgraded
- Dependencies still upgrade when needed (Homebrew handles compatibility)

### 🙏 Feedback

Report bugs or suggest features via [Issues](https://github.com/sandeepyadav1478/homebrew-hushbrew/issues)
