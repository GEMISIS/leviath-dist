# typed: false
# frozen_string_literal: true

require_relative "../lib/verified_strategy"

class Leviath < Formula
  desc "A structured agent runtime for LLMs (stable)"
  homepage "https://leviath.dev"
  license "MIT"
  version "0.3.8"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/GEMISIS/leviath/releases/download/latest/leviath-macos-arm64.tar.gz",
          using: VerifiedGitHubReleaseDownloadStrategy
    else
      url "https://github.com/GEMISIS/leviath/releases/download/latest/leviath-macos-x64.tar.gz",
          using: VerifiedGitHubReleaseDownloadStrategy
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/GEMISIS/leviath/releases/download/latest/leviath-linux-arm64.tar.gz",
          using: VerifiedGitHubReleaseDownloadStrategy
    else
      url "https://github.com/GEMISIS/leviath/releases/download/latest/leviath-linux-x64.tar.gz",
          using: VerifiedGitHubReleaseDownloadStrategy
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
