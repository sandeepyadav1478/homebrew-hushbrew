# Testing the Homebrew Formula Locally

This guide explains how to test the hushbrew formula locally before publishing.

## Prerequisites

- Homebrew installed
- This repository cloned locally
- `coreutils` installed (`brew install coreutils`)

## Quick Test (Without Installing)

### 1. Syntax Check

```bash
# Check Ruby syntax
ruby -c Formula/hushbrew.rb

# Run Homebrew audit
brew audit --strict Formula/hushbrew.rb
```

### 2. Test from Local File

```bash
# Install from local formula file
brew install --build-from-source ./Formula/hushbrew.rb

# Check what was installed
ls -la ~/.local/bin/hushbrew.sh
ls -la ~/.local/bin/brew-curl
cat ~/.config/hushbrew/config
cat ~/Library/LaunchAgents/com.local.hushbrew.plist
```

### 3. Start the Service

```bash
# Start hushbrew
brew services start hushbrew

# Check if it loaded
launchctl list | grep hushbrew
```

### 4. Test Manually

```bash
# Run the script directly
~/.local/bin/hushbrew.sh

# Check the log
tail -f ~/.local/log/hushbrew.log
```

### 5. Cleanup Test Installation

```bash
# Stop the service
brew services stop hushbrew

# Uninstall
brew uninstall hushbrew

# Remove files
rm -rf ~/.local/bin/hushbrew.sh ~/.local/bin/brew-curl
rm -rf ~/.config/hushbrew
rm -rf ~/.local/log/hushbrew*
rm ~/Library/LaunchAgents/com.local.hushbrew.plist
```

## Testing with a Local Tap

Create a local tap to simulate the real installation experience:

```bash
# Create a local tap directory
mkdir -p $(brew --repository)/Library/Taps/local/homebrew-hushbrew

# Copy the formula
cp Formula/hushbrew.rb $(brew --repository)/Library/Taps/local/homebrew-hushbrew/

# Now you can install like users would
brew install local/hushbrew/hushbrew

# Start the service
brew services start local/hushbrew/hushbrew

# Test...

# Cleanup
brew services stop local/hushbrew/hushbrew
brew uninstall local/hushbrew/hushbrew
rm -rf $(brew --repository)/Library/Taps/local/homebrew-hushbrew
```

## Testing Upgrades

Simulate what happens when users upgrade:

```bash
# Make a change to the script
echo "# test change" >> bin/hushbrew.sh

# Reinstall
brew reinstall ./Formula/hushbrew.rb

# Verify the change appears
tail -1 ~/.local/bin/hushbrew.sh
```

## Common Issues

### Issue: Formula Syntax Error

```bash
# Run syntax check
ruby -c Formula/hushbrew.rb

# Run brew audit for detailed errors
brew audit --strict Formula/hushbrew.rb
```

### Issue: Dependencies Not Found

```bash
# Install coreutils
brew install coreutils

# Verify timeout is available
which timeout
```

### Issue: Post-Install Fails

Check the post_install section runs:

```bash
# Reinstall with verbose output
brew reinstall -v ./Formula/hushbrew.rb
```

### Issue: Service Won't Start

```bash
# Check LaunchAgent status
launchctl list | grep hushbrew

# Try loading manually
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.local.hushbrew.plist

# Check for errors
launchctl error $(launchctl list | grep hushbrew | awk '{print $1}')
```

## Validation Checklist

Before publishing, verify:

- [ ] Formula syntax is valid (`ruby -c Formula/hushbrew.rb`)
- [ ] Passes audit (`brew audit --strict Formula/hushbrew.rb`)
- [ ] Installs successfully (`brew install ./Formula/hushbrew.rb`)
- [ ] Post-install creates all files:
  - [ ] `~/.local/bin/hushbrew.sh` exists and is executable
  - [ ] `~/.local/bin/brew-curl` exists and is executable
  - [ ] `~/.config/hushbrew/config` exists
  - [ ] `~/Library/LaunchAgents/com.local.hushbrew.plist` exists
- [ ] Service starts (`brew services start hushbrew`)
- [ ] Script runs manually (`~/.local/bin/hushbrew.sh`)
- [ ] Logs are created (`~/.local/log/hushbrew.log`)
- [ ] Service stops cleanly (`brew services stop hushbrew`)
- [ ] Uninstall works (`brew uninstall hushbrew`)

## Testing on Both Architectures

If you have access to both:

### Apple Silicon (M1/M2/M3)
```bash
# Check brew prefix
echo $HOMEBREW_PREFIX  # Should be /opt/homebrew

# Test installation
brew install ./Formula/hushbrew.rb
~/.local/bin/hushbrew.sh
```

### Intel Mac
```bash
# Check brew prefix
echo $HOMEBREW_PREFIX  # Should be /usr/local

# Test installation
brew install ./Formula/hushbrew.rb
~/.local/bin/hushbrew.sh
```

Both should work identically since the script auto-detects the brew prefix.
