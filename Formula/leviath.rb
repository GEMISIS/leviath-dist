# typed: false
# frozen_string_literal: true

require_relative "../lib/private_strategy"

# Stable release (not yet available — use leviath-alpha for now)
class Leviath < Formula
  desc "A structured agent runtime for LLMs (stable)"
  homepage "https://leviath.dev"
  license "MIT"
  version "0.1.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Sun-Forge-AI/leviath/releases/download/v#{version}/leviath-macos-arm64.tar.gz",
          using: GitHubPrivateRepositoryReleaseDownloadStrategy
    else
      url "https://github.com/Sun-Forge-AI/leviath/releases/download/v#{version}/leviath-macos-x64.tar.gz",
          using: GitHubPrivateRepositoryReleaseDownloadStrategy
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Sun-Forge-AI/leviath/releases/download/v#{version}/leviath-linux-arm64.tar.gz",
          using: GitHubPrivateRepositoryReleaseDownloadStrategy
    else
      url "https://github.com/Sun-Forge-AI/leviath/releases/download/v#{version}/leviath-linux-x64.tar.gz",
          using: GitHubPrivateRepositoryReleaseDownloadStrategy
    end
  end

  conflicts_with "leviath-alpha", because: "both install the `lev` binary"
  conflicts_with "leviath-beta", because: "both install the `lev` binary"

  def install
    bin.install "lev"
  end

  test do
    assert_match "leviath", shell_output("#{bin}/lev --version")
  end
end
