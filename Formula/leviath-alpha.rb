# typed: false
# frozen_string_literal: true

require_relative "../lib/verified_strategy"

class LeviathAlpha < Formula
  desc "A structured agent runtime for LLMs (nightly alpha)"
  homepage "https://leviath.dev"
  license "MIT"
  version "0.1.1-alpha.20260731"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/GEMISIS/leviath/releases/download/alpha/leviath-macos-arm64.tar.gz",
          using: VerifiedGitHubReleaseDownloadStrategy
    else
      url "https://github.com/GEMISIS/leviath/releases/download/alpha/leviath-macos-x64.tar.gz",
          using: VerifiedGitHubReleaseDownloadStrategy
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/GEMISIS/leviath/releases/download/alpha/leviath-linux-arm64.tar.gz",
          using: VerifiedGitHubReleaseDownloadStrategy
    else
      url "https://github.com/GEMISIS/leviath/releases/download/alpha/leviath-linux-x64.tar.gz",
          using: VerifiedGitHubReleaseDownloadStrategy
    end
  end

  conflicts_with "leviath", because: "both install the `lev` binary"
  conflicts_with "leviath-beta", because: "both install the `lev` binary"

  def install
    bin.install "lev"
  end

  test do
    assert_match "leviath", shell_output("#{bin}/lev --version")
  end
end
