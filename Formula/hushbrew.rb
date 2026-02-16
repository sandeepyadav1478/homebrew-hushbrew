# typed: false
# frozen_string_literal: true

# Formula for hushbrew - Automatic daily Homebrew upgrades for macOS
class Hushbrew < Formula
  desc "Automatic daily Homebrew upgrades for macOS that stay out of your way"
  homepage "https://github.com/sandeepyadav1478/homebrew-hushbrew"
  url "https://github.com/sandeepyadav1478/homebrew-hushbrew/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "2b0c33a4ee53f7ce61e8eb5fd1a89959d7bf252fbf8876c56450323a88a1dd3d"
  license "MIT"
  head "https://github.com/sandeepyadav1478/homebrew-hushbrew.git", branch: "main"

  # hushbrew is macOS-specific (uses pmset, osascript, ioreg, LaunchAgent)
  depends_on :macos
  # Requires GNU timeout from coreutils
  depends_on "coreutils"

  livecheck do
    url :stable
    strategy :github_latest
  end

  def install
    # Install scripts to libexec
    libexec.install "bin/hushbrew.sh"
    libexec.install "bin/brew-curl"
    libexec.install "bin/hushbrew-setup"

    # Store the plist template
    (libexec/"launchd").mkpath
    (libexec/"launchd").install "launchd/com.local.hushbrew.plist"

    # Install main hushbrew command
    bin.install "bin/hushbrew"
  end

  def caveats
    <<~EOS
      To start hushbrew, run:
        hushbrew start

      This will set up and start automatic Homebrew upgrades.
      Runs at 10 AM, 2 PM, and 6 PM daily.

      Other commands:
        hushbrew stop     - Stop the service
        hushbrew status   - Show status
        hushbrew logs     - View logs
        hushbrew run      - Run upgrade manually
        hushbrew help     - Show all commands

      Features:
        • Meeting-aware (Zoom, Slack, mic detection)
        • Power-aware (skips if battery <15%)
        • Bandwidth throttling (60% of detected speed)

      Configuration:
        ~/.config/hushbrew/config
    EOS
  end

  # Note: Use 'hushbrew start' instead of 'brew services start' for calendar-based scheduling
  service do
    run opt_libexec/"hushbrew.sh"
    working_dir Dir.home
    keep_alive false
    log_path var/"log/hushbrew.log"
    error_log_path var/"log/hushbrew.log"
  end

  def post_uninstall
    # Stop and unload the LaunchAgent
    quiet_system "launchctl", "bootout", "gui/#{Process.uid}/com.local.hushbrew"
  end

  def zap
    # Remove user files
    rm_f [
      "#{Dir.home}/.local/bin/hushbrew.sh",
      "#{Dir.home}/.local/bin/brew-curl",
      "#{Dir.home}/.local/log/hushbrew.log",
      "#{Dir.home}/.local/log/hushbrew.log.old",
      "#{Dir.home}/.local/log/hushbrew.lastrun",
      "#{Dir.home}/Library/LaunchAgents/com.local.hushbrew.plist",
    ]

    # Remove config directory
    rm_rf "#{Dir.home}/.config/hushbrew"

    # Try to remove directories if empty
    rmdir ["#{Dir.home}/.local/log", "#{Dir.home}/.local/bin"].select { |d| File.directory?(d) && Dir.empty?(d) }

    # Remove lock file
    rmdir "/tmp/hushbrew.lock" if File.directory?("/tmp/hushbrew.lock")
  end

  test do
    # Test that scripts have valid syntax
    system "bash", "-n", opt_libexec/"hushbrew.sh"
    system "bash", "-n", opt_libexec/"brew-curl"
    system "bash", "-n", opt_libexec/"hushbrew-setup"

    # Verify main command works
    assert_match "hushbrew v", shell_output("#{bin}/hushbrew version")
    assert_match "Automatic Homebrew upgrades", shell_output("#{bin}/hushbrew help")

    # Verify plist template exists
    assert_predicate opt_libexec/"launchd/com.local.hushbrew.plist", :exist?

    # Verify plist has expected content
    plist_content = (opt_libexec/"launchd/com.local.hushbrew.plist").read
    assert_match "__HOME__", plist_content
    assert_match "StartCalendarInterval", plist_content

    # Verify all required scripts are executable
    assert_predicate opt_libexec/"hushbrew.sh", :executable?
    assert_predicate opt_libexec/"brew-curl", :executable?
    assert_predicate opt_libexec/"hushbrew-setup", :executable?
    assert_predicate bin/"hushbrew", :executable?
  end
end
