<p align="center">
  <h1 align="center">Leviath</h1>
  <p align="center">
    <strong>A structured agent runtime for LLMs</strong>
  </p>
</p>

<div align="center">

| Linux | macOS | Windows | Coverage |
| :-: | :-: | :-: | :-: |
| [![Linux](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/GEMISIS/b35e030175e78fad8e3562e58be21c60/raw/leviath-test-ubuntu-latest.json)](https://github.com/Sun-Forge-AI/leviath/actions/workflows/ci.yml) | [![macOS](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/GEMISIS/b35e030175e78fad8e3562e58be21c60/raw/leviath-test-macos-latest.json)](https://github.com/Sun-Forge-AI/leviath/actions/workflows/ci.yml) | [![Windows](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/GEMISIS/b35e030175e78fad8e3562e58be21c60/raw/leviath-test-windows-latest.json)](https://github.com/Sun-Forge-AI/leviath/actions/workflows/ci.yml) | [![Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/GEMISIS/b35e030175e78fad8e3562e58be21c60/raw/leviath-coverage-lines.json)](https://github.com/Sun-Forge-AI/leviath/actions/workflows/ci.yml) |

</div>

<p align="center">
  <a href="https://github.com/Sun-Forge-AI/leviath/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://leviath.dev"><img src="https://img.shields.io/badge/docs-leviath.dev-8b5cf6" alt="Docs"></a>
</p>

---

Most agent tools give LLMs a flat message array and hope for the best. Leviath gives them structure — structured memory, multi-stage workflows, and an ECS engine — so agents stay coherent on long tasks, use the right model for each phase, and don't melt your machine when you run a dozen at once.

Pick a pre-built agent or create your own. Run it. Watch it actually remember what it read 50 tool calls ago.

## ⚠️ Private Alpha — Setup Required

This repo and its releases are **private**. Before installing, you'll need a GitHub Personal Access Token (PAT) with `repo` scope:

1. Go to [github.com/settings/tokens](https://github.com/settings/tokens) → **Generate new token (classic)**
2. Select the **`repo`** scope (full control of private repositories)
3. Generate and copy the token

Then configure git to authenticate with private Sun-Forge-AI repos:

**macOS / Linux:**

```bash
# Replace ghp_your_token_here with your actual PAT

# Lets git clone the private tap/bucket (used by `brew tap` / `scoop bucket add`)
git config --global url."https://ghp_your_token_here@github.com/Sun-Forge-AI/".insteadOf "https://github.com/Sun-Forge-AI/"

# Lets Homebrew download the private release binaries (git config does NOT
# cover this -- brew fetches assets with curl via the GitHub API):
export HOMEBREW_GITHUB_API_TOKEN="ghp_your_token_here"  # add to ~/.zshrc or ~/.bashrc

# For the Linux install script, also export the token:
export GITHUB_TOKEN="ghp_your_token_here"  # add to ~/.zshrc or ~/.bashrc
```

> Already using the [GitHub CLI](https://cli.github.com)? You can skip the exports —
> the formulas fall back to `gh auth token` automatically.

**Windows:**

```powershell
# Replace ghp_your_token_here with your actual PAT
git config --global url."https://ghp_your_token_here@github.com/Sun-Forge-AI/".insteadOf "https://github.com/Sun-Forge-AI/"

# For Scoop, also set:
$env:SCOOP_GH_TOKEN = "ghp_your_token_here"  # add to $PROFILE for persistence
```

The git config covers `brew tap` and `scoop bucket add` (git clones). The exported tokens cover the actual binary downloads, which go through the GitHub API — private release assets return 404 for plain URL fetches, even authenticated ones.

> **Note:** You also need to be added as a collaborator on this repo. If you can read this, you're good.

## Release Channels

Leviath has three release channels. **Only alpha is currently available.**

| Channel | Schedule | Stability | Install command |
|---------|----------|-----------|-----------------|
| **Alpha** | Nightly | ⚠️ Bleeding edge | `brew install leviath-alpha` |
| **Beta** | Weekly (Monday) | 🟡 Tested | `brew install leviath-beta` (coming soon) |
| **Stable** | Weekly (Thursday, approved) | ✅ Production | `brew install leviath` (coming soon) |

## Installation

### macOS (Homebrew)

```bash
# Add the tap (one time)
brew tap sun-forge-ai/leviath https://github.com/Sun-Forge-AI/leviath-dist.git

# Newer Homebrew requires explicitly trusting third-party taps (one time)
brew trust sun-forge-ai/leviath

# Install alpha (currently the only available channel)
brew install leviath-alpha

# Future: install stable or beta
# brew install leviath
# brew install leviath-beta
```

To update:

```bash
brew update && brew upgrade leviath-alpha
```

> **Note:** Only one channel can be installed at a time. Switch channels with `brew uninstall leviath-alpha && brew install leviath-beta`.

### Linux

**Quick install** (alpha channel, x86_64/arm64):

```bash
curl -fsSL https://raw.githubusercontent.com/Sun-Forge-AI/leviath-dist/main/install.sh | bash
```

To install a specific channel:

```bash
curl -fsSL https://raw.githubusercontent.com/Sun-Forge-AI/leviath-dist/main/install.sh | bash -s -- --channel alpha
# Also: --channel beta, --channel stable (when available)
```

**Manual install:**

1. Download the latest release from [GitHub Releases](https://github.com/Sun-Forge-AI/leviath/releases)
2. Extract and move to your PATH:

```bash
tar xzf leviath-linux-x64.tar.gz
sudo mv lev /usr/local/bin/
```

### Windows

**Scoop** (recommended):

```powershell
scoop bucket add leviath https://github.com/Sun-Forge-AI/leviath-dist.git

# Install alpha (currently the only available channel)
scoop install leviath-alpha

# Future: scoop install leviath / leviath-beta
```

To update:

```powershell
scoop update leviath-alpha
```

**Manual install:**

1. Download `leviath-windows-x64.zip` from [GitHub Releases](https://github.com/Sun-Forge-AI/leviath/releases)
2. Extract `lev.exe`
3. Add the folder containing `lev.exe` to your `PATH`

### Build from Source (any platform)

Requires [Rust](https://rustup.rs/) (stable toolchain):

```bash
cargo install --git https://github.com/Sun-Forge-AI/leviath.git --bin lev
```

## Quick Start

### 1. Configure a Provider

You need at least one LLM provider. Run the interactive setup:

```bash
lev setup
```

This walks you through adding API keys for any supported provider. You can also pass keys directly:

```bash
lev setup --non-interactive --anthropic-key sk-ant-...
```

**Supported providers:** [Anthropic](https://console.anthropic.com/) · [OpenAI](https://platform.openai.com/) · [Google (Gemini)](https://aistudio.google.com/) · [OpenRouter](https://openrouter.ai/) · [Ollama](https://ollama.com) (local, free)

### 2. Run an Agent

```bash
# Coding
lev run coder --task "Build a CLI that converts CSV to JSON"

# Research
lev run deep-researcher --task "Survey the current state of solid-state battery technology"

# Full software engineering workflow
lev run software-engineer --task "Add input validation to the user registration endpoint"
```

### 3. Watch It Work

Open the TUI dashboard:

```bash
lev dash
```

### 4. Create Your Own Agent

```bash
lev create my-agent
cd my-agent
lev run . --task "Your task here"
```

This scaffolds an `agent.leviath` config you can customize — models per stage, context regions, tools, interaction points.

## Pre-built Agents

Nine agents ship out of the box:

| Agent | Stages | Best For |
|-------|--------|----------|
| **software-engineer** | plan ⇄ implement ⇄ review | Full coding workflow with graph transitions |
| **coder** | analyze → implement ⇄ review | Focused implementation with review loop |
| **reviewer** | scan → deep_review → report | Code review and audit |
| **deep-researcher** | gather ⇄ analyze → synthesize | Thorough single-topic investigation |
| **wide-researcher** | survey ⇄ compare → summarize | Broad multi-topic landscape survey |
| **researcher** | gather ⇄ analyze → summarize | General-purpose research |
| **log-analyzer** | ingest → analyze ⇄ script → report | Log file analysis |
| **daily-briefer** | collect → prioritize → brief | Morning summaries |
| **writing-assistant** | research → outline → draft ⇄ edit | Blog posts, reports, docs |

## CLI Reference

| Command | Description |
|---------|-------------|
| `lev run [path] --task "..."` | Run an agent |
| `lev dash` | TUI dashboard |
| `lev serve` | REST + WebSocket API server |
| `lev create <name>` | Create agent project |
| `lev validate [path]` | Validate agent blueprint |
| `lev pack` / `lev add` / `lev remove` | Package management |
| `lev list` | List available agents |
| `lev test` | Run agent tests |
| `lev setup` / `lev models` | Provider configuration |

## Requirements

- An API key from a supported provider — or run Ollama locally (free, no key)
- macOS, Linux, or Windows
- No runtime dependencies — single binary, no Node/Python/Docker

## Troubleshooting

**`lev: command not found`** — Make sure the binary is on your PATH:
- macOS: Homebrew handles this automatically
- Linux: The install script puts it in `/usr/local/bin`. If you installed manually, ensure the binary location is in your `$PATH`
- Windows: Add the folder containing `lev.exe` to your system PATH ([guide](https://www.architectryan.com/2018/03/17/add-to-the-path-on-windows-10/))

**Provider connection errors** — Run `lev setup` to verify your API key is configured correctly. For Ollama, make sure the server is running (`ollama serve`).

**Permission denied (Linux)** — Make sure the binary is executable: `chmod +x /usr/local/bin/lev`

## Links

- 📖 [Documentation](https://leviath.dev/docs)
- 🐛 [Report an Issue](https://github.com/Sun-Forge-AI/leviath/issues)
- 📜 [License (MIT)](https://github.com/Sun-Forge-AI/leviath/blob/main/LICENSE)
