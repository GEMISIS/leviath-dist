# frozen_string_literal: true

require "digest"
require "download_strategy"
require "json"
require "utils/popen"

# Download strategy for release assets of *private* GitHub repositories.
#
# Homebrew fetches formula URLs with plain curl, so the usual
# `git config url.insteadOf` token trick (which only affects git) never
# applies, and https://github.com/<owner>/<repo>/releases/download/... on a
# private repo always returns 404 — even WITH an Authorization header.
# Private release assets are only downloadable through the REST API asset
# endpoint (https://api.github.com/.../releases/assets/<id>) with
# `Accept: application/octet-stream`, which is what this strategy does.
#
# Every download is verified against the release's own SHA256SUMS before it is
# handed to Homebrew. A formula normally pins a literal `sha256`, but these are
# rolling channel tags — `alpha` is re-uploaded on every build — so a pinned
# hash would be wrong within a day. Verifying against the checksums file
# published beside the asset keeps the guarantee without pinning. See the
# caveat on `verify_checksum!` for what that does and does not buy.
#
# Token lookup order:
#   1. HOMEBREW_GITHUB_API_TOKEN (survives brew's environment filtering)
#   2. GITHUB_TOKEN (works when brew is invoked with it in scope)
#   3. `gh auth token` (GitHub CLI, if installed and logged in)
class GitHubPrivateRepositoryReleaseDownloadStrategy < CurlDownloadStrategy
  # The checksums file published alongside every release asset.
  CHECKSUM_FILE = "SHA256SUMS"

  def initialize(url, name, version, **meta)
    super
    match = url.match(%r{https://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/(\S+)})
    raise CurlDownloadStrategyError, "Invalid GitHub release asset URL: #{url}" unless match

    @owner, @repo, @tag, @filename = match.captures
  end

  private

  def github_token
    @github_token ||= begin
      token = ENV["HOMEBREW_GITHUB_API_TOKEN"] || ENV["GITHUB_TOKEN"] || gh_cli_token
      if token.nil? || token.empty?
        raise CurlDownloadStrategyError, <<~EOS
          No GitHub token available to download a private release asset.
          Set one before installing (a PAT with `repo` scope):
            export HOMEBREW_GITHUB_API_TOKEN=ghp_your_token_here
          or log in with the GitHub CLI: gh auth login
        EOS
      end
      token
    end
  end

  def gh_cli_token
    token = Utils.popen_read("gh", "auth", "token").strip
    token.empty? ? nil : token
  rescue StandardError
    nil
  end

  def release
    @release ||= begin
      result = curl_output(
        "--silent", "--location",
        "--header", "Authorization: token #{github_token}",
        "--header", "Accept: application/vnd.github+json",
        "https://api.github.com/repos/#{@owner}/#{@repo}/releases/tags/#{@tag}"
      )
      unless result.success?
        raise CurlDownloadStrategyError,
              "Failed to fetch release metadata for #{@owner}/#{@repo} tag #{@tag}. Bad token?"
      end

      JSON.parse(result.stdout)
    end
  end

  def asset_id(name)
    asset = (release["assets"] || []).find { |a| a["name"] == name }
    if asset.nil?
      raise CurlDownloadStrategyError,
            "Release #{@tag} has no asset named #{name}. " \
            "Available: #{(release["assets"] || []).map { |a| a["name"] }.join(", ")}"
    end

    asset["id"]
  end

  def download_asset(name, to:, timeout: nil)
    curl_download(
      "https://api.github.com/repos/#{@owner}/#{@repo}/releases/assets/#{asset_id(name)}",
      "--header", "Authorization: token #{github_token}",
      "--header", "Accept: application/octet-stream",
      to: to, timeout: timeout
    )
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
    sums = Pathname.new("#{path}.SHA256SUMS")
    begin
      download_asset(CHECKSUM_FILE, to: sums)
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
    return if actual.casecmp?(expected)

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
    download_asset(@filename, to: temporary_path, timeout: timeout)
    verify_checksum!(temporary_path)
  end
end
