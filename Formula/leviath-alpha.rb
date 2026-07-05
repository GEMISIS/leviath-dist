# typed: false
# frozen_string_literal: true

class LeviathAlpha < Formula
  desc "A structured agent runtime for LLMs (nightly alpha)"
  homepage "https://leviath.dev"
  license "MIT"
  version "0.1.0-alpha"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Sun-Forge-AI/leviath/releases/download/alpha/leviath-macos-arm64.tar.gz"
    else
      url "https://github.com/Sun-Forge-AI/leviath/releases/download/alpha/leviath-macos-x64.tar.gz"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Sun-Forge-AI/leviath/releases/download/alpha/leviath-linux-arm64.tar.gz"
    else
      url "https://github.com/Sun-Forge-AI/leviath/releases/download/alpha/leviath-linux-x64.tar.gz"
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
