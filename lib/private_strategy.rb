# frozen_string_literal: true

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
# Token lookup order:
#   1. HOMEBREW_GITHUB_API_TOKEN (survives brew's environment filtering)
#   2. GITHUB_TOKEN (works when brew is invoked with it in scope)
#   3. `gh auth token` (GitHub CLI, if installed and logged in)
class GitHubPrivateRepositoryReleaseDownloadStrategy < CurlDownloadStrategy
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

  def asset_id
    @asset_id ||= begin
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

      release = JSON.parse(result.stdout)
      asset = (release["assets"] || []).find { |a| a["name"] == @filename }
      if asset.nil?
        raise CurlDownloadStrategyError,
              "Release #{@tag} has no asset named #{@filename}. " \
              "Available: #{(release["assets"] || []).map { |a| a["name"] }.join(", ")}"
      end

      asset["id"]
    end
  end

  def _fetch(url:, resolved_url:, timeout:)
    curl_download(
      "https://api.github.com/repos/#{@owner}/#{@repo}/releases/assets/#{asset_id}",
      "--header", "Authorization: token #{github_token}",
      "--header", "Accept: application/octet-stream",
      to: temporary_path, timeout: timeout
    )
  end
end
