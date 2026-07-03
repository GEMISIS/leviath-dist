# typed: false
# frozen_string_literal: true

class Leviath < Formula
  desc "A structured agent runtime for LLMs"
  homepage "https://leviath.dev"
  license "MIT"
  version "0.1.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/GEMISIS/leviath-dist/releases/download/v#{version}/leviath-macos-arm64.tar.gz"
      # sha256 "REPLACE_WITH_ACTUAL_SHA256_ARM64"
    else
      url "https://github.com/GEMISIS/leviath-dist/releases/download/v#{version}/leviath-macos-x64.tar.gz"
      # sha256 "REPLACE_WITH_ACTUAL_SHA256_X64"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/GEMISIS/leviath-dist/releases/download/v#{version}/leviath-linux-arm64.tar.gz"
      # sha256 "REPLACE_WITH_ACTUAL_SHA256_LINUX_ARM64"
    else
      url "https://github.com/GEMISIS/leviath-dist/releases/download/v#{version}/leviath-linux-x64.tar.gz"
      # sha256 "REPLACE_WITH_ACTUAL_SHA256_LINUX_X64"
    end
  end

  def install
    bin.install "lev"
  end

  test do
    assert_match "leviath", shell_output("#{bin}/lev --version")
  end
end
