# frozen_string_literal: true

require "digest"
require "download_strategy"

# Download strategy for Leviath's GitHub release assets.
#
# The repos are public, so plain curl fetches the assets — no token, no API.
# What this adds over Homebrew's stock CurlDownloadStrategy is verification:
# every download is checked against the SHA256SUMS file published in the same
# release before it is handed to Homebrew. A formula normally pins a literal
# `sha256`, but these are rolling channel tags — `alpha` is re-uploaded on
# every build — so a pinned hash would be wrong within a day. Verifying against
# the checksums file published beside the asset keeps the guarantee without
# pinning. See the caveat on `verify_checksum!` for what that does and does
# not buy.
#
# Note that Homebrew only calls `_fetch` when it actually downloads: an archive
# already in its cache is reused without re-running this, which is the same
# trust boundary as the rest of the user's own cache.
class VerifiedGitHubReleaseDownloadStrategy < CurlDownloadStrategy
  # The checksums file published alongside every release asset.
  CHECKSUM_FILE = "SHA256SUMS"

  def initialize(url, name, version, **meta)
    super
    match = url.match(%r{https://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/(\S+)})
    raise CurlDownloadStrategyError, "Invalid GitHub release asset URL: #{url}" unless match

    @owner, @repo, @tag, @filename = match.captures
  end

  private

  def checksum_url
    "https://github.com/#{@owner}/#{@repo}/releases/download/#{@tag}/#{CHECKSUM_FILE}"
  end

  # Refuse anything whose SHA-256 is not the one published beside it.
  #
  # What this does and does not buy: the checksums file comes from the same
  # release as the asset, so it does not stop someone who can rewrite the whole
  # release — that needs a signature checked against a trusted identity. It does
  # catch a corrupted or truncated download, a tampered or swapped *asset*, and
  # a cache or mirror serving something else, which is the class this formula
  # could previously not detect at all.
  def verify_checksum!(path)
    sums = Pathname.new("#{path}.#{CHECKSUM_FILE}")
    begin
      curl_download(checksum_url, to: sums)
      expected = sums.read.each_line.find { |l| l.split(/\s+/, 2)[1].to_s.strip == @filename }
                     &.split(/\s+/, 2)&.first&.strip
    ensure
      sums.unlink if sums.exist?
    end

    if expected.nil? || expected.empty?
      raise CurlDownloadStrategyError,
            "#{CHECKSUM_FILE} in release #{@tag} has no entry for #{@filename}. Refusing to install."
    end

    actual = Digest::SHA256.file(path).hexdigest
    if actual.casecmp?(expected)
      # Say so explicitly. Homebrew prints "Cannot verify integrity ... No
      # checksum was provided" whenever a formula carries no literal `sha256`,
      # which is the opposite of what just happened — without this line the last
      # word a user reads is that nothing was checked.
      ohai "Verified #{@filename} against #{CHECKSUM_FILE} (#{expected})"
      return
    end

    path.unlink if path.exist?
    raise CurlDownloadStrategyError, <<~EOS
      Checksum mismatch for #{@filename}.
        expected: #{expected}
        actual:   #{actual}
      This means the file you received is not the one that was published.
      It has been deleted rather than installed.
    EOS
  end

  def _fetch(url:, resolved_url:, timeout:)
    super
    verify_checksum!(temporary_path)
  end
end
