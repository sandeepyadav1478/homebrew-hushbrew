# Setting Up the Homebrew Formula

This guide explains how to publish hushbrew as a Homebrew tap so users can install it with `brew install`.

## Prerequisites

1. A GitHub account
2. A public repository for hushbrew
3. Git installed locally

## Step 1: Create GitHub Repository

1. Create a new repository named `homebrew-hushbrew` on GitHub
   - Repository name MUST start with `homebrew-` for Homebrew tap convention
   - Example: `https://github.com/YOUR_USERNAME/homebrew-hushbrew`

2. Or, if using the main repo as a tap, the repo can be named just `hushbrew`
   - Users will tap it as: `YOUR_USERNAME/hushbrew`

## Step 2: Update Formula URLs

Edit `Formula/hushbrew.rb` and replace placeholders:

1. Replace `YOUR_USERNAME` with your GitHub username in these lines:
   ```ruby
   homepage "https://github.com/YOUR_USERNAME/hushbrew"
   url "https://github.com/YOUR_USERNAME/hushbrew/archive/refs/tags/v1.0.0.tar.gz"
   head "https://github.com/YOUR_USERNAME/hushbrew.git", branch: "main"
   ```

2. Create a git tag and release:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

3. Generate SHA256 checksum:
   ```bash
   # Download the release tarball
   curl -L https://github.com/YOUR_USERNAME/hushbrew/archive/refs/tags/v1.0.0.tar.gz -o hushbrew-1.0.0.tar.gz

   # Generate SHA256
   shasum -a 256 hushbrew-1.0.0.tar.gz
   ```

4. Replace `YOUR_SHA256_CHECKSUM_HERE` with the actual checksum

## Step 3: Push to GitHub

```bash
git add .
git commit -m "Add Homebrew formula"
git remote add origin https://github.com/YOUR_USERNAME/homebrew-hushbrew.git
git push -u origin main
```

## Step 4: Test the Formula Locally

Before publishing, test locally:

```bash
# Install from local formula
brew install --build-from-source Formula/hushbrew.rb

# Or test the formula
brew test Formula/hushbrew.rb

# Audit the formula
brew audit --strict --online hushbrew
```

## Step 5: User Installation

Once published, users can install hushbrew with:

```bash
# Option 1: Tap then install
brew tap YOUR_USERNAME/hushbrew
brew install hushbrew

# Option 2: Direct install (no tap needed)
brew install YOUR_USERNAME/hushbrew/hushbrew
```

## Repository Structure Options

### Option A: Dedicated Tap Repository (Recommended)
```
homebrew-hushbrew/
├── Formula/
│   └── hushbrew.rb
├── README.md
└── (formula-specific files)
```

Users: `brew tap YOUR_USERNAME/hushbrew && brew install hushbrew`

### Option B: Main Repository as Tap
```
hushbrew/
├── Formula/
│   └── hushbrew.rb
├── bin/
│   ├── hushbrew.sh
│   └── brew-curl
├── launchd/
├── README.md
└── (all project files)
```

Users: `brew install YOUR_USERNAME/hushbrew/hushbrew`

## Updating the Formula

When you release a new version:

1. Create a new git tag:
   ```bash
   git tag -a v1.1.0 -m "Release version 1.1.0"
   git push origin v1.1.0
   ```

2. Update `Formula/hushbrew.rb`:
   - Change `url` to point to new version
   - Update `sha256` with new checksum

3. Users update with:
   ```bash
   brew update
   brew upgrade hushbrew
   ```

## Formula Guidelines

- Follow [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- Run `brew audit --strict` before releasing
- Test on both Intel and Apple Silicon if possible
- Keep dependencies minimal (currently only `coreutils`)

## Publishing to Homebrew Core (Optional)

To submit hushbrew to the official Homebrew repository:

1. Ensure formula passes all audits
2. Get significant user adoption (stars, usage)
3. Follow [Homebrew Contribution Guide](https://docs.brew.sh/How-To-Open-a-Homebrew-Pull-Request)
4. Submit PR to [homebrew-core](https://github.com/Homebrew/homebrew-core)

This allows users to install with just: `brew install hushbrew` (no tap needed)
