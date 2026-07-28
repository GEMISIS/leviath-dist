# Leviath installer for Windows
#
# Usage (PowerShell):
#   $env:GITHUB_TOKEN = "ghp_your_token_here"   # PAT with `repo` scope (private phase)
#   irm -Headers @{Authorization="token $env:GITHUB_TOKEN"} https://raw.githubusercontent.com/Sun-Forge-AI/leviath-dist/main/install.ps1 | iex
#
# Or download this file and run:
#   .\install.ps1 -Channel alpha    # alpha (default) | beta | stable

param(
    [ValidateSet("alpha", "beta", "stable")]
    [string]$Channel = "alpha"
)

$ErrorActionPreference = "Stop"

$Repo = "Sun-Forge-AI/leviath"
$AssetName = "leviath-windows-x64.zip"
$InstallDir = Join-Path $env:LOCALAPPDATA "Leviath\bin"

# Channel -> release tag (rolling channel releases)
$TagMap = @{ alpha = "alpha"; beta = "beta"; stable = "latest" }
$ReleaseTag = $TagMap[$Channel]

# Token: GITHUB_TOKEN env var, else the GitHub CLI's stored credentials.
$Token = $env:GITHUB_TOKEN
if (-not $Token) {
    try { $Token = (& gh auth token 2>$null | Out-String).Trim() } catch { $Token = $null }
}

$ApiHeaders = @{ "Accept" = "application/vnd.github+json" }
if ($Token) { $ApiHeaders["Authorization"] = "token $Token" }

Write-Host "==> Channel: $Channel"
Write-Host "==> Fetching $Channel release..."
try {
    $Release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/tags/$ReleaseTag" -Headers $ApiHeaders
} catch {
    throw "Failed to fetch release info for '$ReleaseTag'. For private repos, set `$env:GITHUB_TOKEN to a PAT with 'repo' scope (or run 'gh auth login')."
}

$Asset = @($Release.assets | Where-Object { $_.name -eq $AssetName })[0]
if (-not $Asset) {
    throw "No release asset named $AssetName in release '$ReleaseTag'. See https://github.com/$Repo/releases"
}

$ChecksumName = "SHA256SUMS"
$ChecksumAsset = @($Release.assets | Where-Object { $_.name -eq $ChecksumName })[0]
if (-not $ChecksumAsset) {
    throw "This release publishes no $ChecksumName, so the download cannot be verified. Refusing to install."
}

# Private release assets 404 on browser_download_url even with a token --
# they must be downloaded through the API asset endpoint with
# Accept: application/octet-stream. Public assets work through it too.
$DlHeaders = @{ "Accept" = "application/octet-stream" }
if ($Token) { $DlHeaders["Authorization"] = "token $Token" }

$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) "leviath-install-$PID"
New-Item -ItemType Directory -Force -Path $Tmp | Out-Null
try {
    $ZipPath = Join-Path $Tmp $AssetName

    Write-Host "==> Downloading $AssetName..."
    Invoke-WebRequest -Uri $Asset.url -Headers $DlHeaders -OutFile $ZipPath

    $SumsPath = Join-Path $Tmp $ChecksumName
    Write-Host "==> Downloading $ChecksumName..."
    Invoke-WebRequest -Uri $ChecksumAsset.url -Headers $DlHeaders -OutFile $SumsPath

    # Verify before unpacking, and refuse to continue on any doubt.
    #
    # What this does and does not buy: the checksum comes from the same release
    # as the archive, so it does not protect against someone who can rewrite the
    # whole release -- that needs a signature checked against a trusted
    # identity, which is tracked separately. It does catch a corrupted or
    # truncated download, a tampered or swapped *asset*, and a cache or mirror
    # serving something else, which is the class this installer could
    # previously not detect at all.
    Write-Host "==> Verifying checksum..."
    $Expected = $null
    foreach ($Line in Get-Content $SumsPath) {
        # `<sha256>  <name>`, the format `sha256sum` writes.
        $Parts = $Line -split '\s+', 2
        if ($Parts.Count -eq 2 -and $Parts[1].Trim() -eq $AssetName) {
            $Expected = $Parts[0].Trim()
            break
        }
    }
    if (-not $Expected) {
        throw "$ChecksumName has no entry for $AssetName. Refusing to install."
    }

    $Actual = (Get-FileHash -Path $ZipPath -Algorithm SHA256).Hash
    if ($Actual -ine $Expected) {
        throw @"
Checksum mismatch for $AssetName.
  expected: $Expected
  actual:   $Actual
This means the file you received is not the one that was published. Do not
install it. Re-run to retry, and report it if it persists.
"@
    }
    Write-Host "==> Checksum verified ($($Expected.ToLower()))"

    Write-Host "==> Installing to $InstallDir..."
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    Expand-Archive -Path $ZipPath -DestinationPath $InstallDir -Force
} finally {
    Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}

# Add the install dir to the user PATH if it isn't there yet.
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (($UserPath -split ";") -notcontains $InstallDir) {
    [Environment]::SetEnvironmentVariable("Path", "$UserPath;$InstallDir", "User")
    Write-Host "==> Added $InstallDir to your user PATH (open a new terminal to pick it up)"
}
$env:Path = "$env:Path;$InstallDir"

Write-Host "==> Leviath ($Channel) installed."
& (Join-Path $InstallDir "lev.exe") --version
Write-Host ""
Write-Host "Get started:"
Write-Host "  lev setup        # configure an LLM provider"
Write-Host '  lev run coder --task "Your task here"'
