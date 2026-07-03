<p align="center">
  <h1 align="center">Leviath</h1>
  <p align="center">
    <strong>A structured agent runtime for LLMs</strong>
  </p>
</p>

<div align="center">

| Linux | macOS | Windows | Coverage |
| :-: | :-: | :-: | :-: |
| [![Linux](https://github.com/GEMISIS/leviath/actions/workflows/ci.yml/badge.svg?branch=main&event=push&job=Test%20%28ubuntu-latest%29)](https://github.com/GEMISIS/leviath/actions/workflows/ci.yml) | [![macOS](https://github.com/GEMISIS/leviath/actions/workflows/ci.yml/badge.svg?branch=main&event=push&job=Test%20%28macos-latest%29)](https://github.com/GEMISIS/leviath/actions/workflows/ci.yml) | [![Windows](https://github.com/GEMISIS/leviath/actions/workflows/ci.yml/badge.svg?branch=main&event=push&job=Test%20%28windows-latest%29)](https://github.com/GEMISIS/leviath/actions/workflows/ci.yml) | [![Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/GEMISIS/b35e030175e78fad8e3562e58be21c60/raw/leviath-coverage-lines.json)](https://github.com/GEMISIS/leviath/actions/workflows/ci.yml) |

</div>

<p align="center">
  <a href="https://leviath.dev"><img src="https://img.shields.io/badge/docs-leviath.dev-8b5cf6" alt="Docs"></a>
  <a href="https://github.com/GEMISIS/leviath/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
</p>

---

Most agent tools give LLMs a flat message array and hope for the best. Leviath gives them structure — structured memory, multi-stage workflows, and an ECS engine — so agents stay coherent on long tasks, use the right model for each phase, and don't melt your machine when you run a dozen at once.

Pick a pre-built agent or create your own. Run it. Watch it actually remember what it read 50 tool calls ago.

## Installation

### macOS (Homebrew)

```bash
brew tap gemisis/leviath https://github.com/GEMISIS/leviath-dist.git
brew install leviath
```

To update:

```bash
brew update && brew upgrade leviath
```

### Linux

**Quick install** (x86_64):

```bash
curl -fsSL https://raw.githubusercontent.com/GEMISIS/leviath-dist/main/install.sh | bash
```

**Manual install:**

1. Download the latest release from [GitHub Releases](https://github.com/GEMISIS/leviath-dist/releases)
2. Extract and move to your PATH:

```bash
tar xzf leviath-linux-x64.tar.gz
sudo mv lev /usr/local/bin/
```

### Windows

**Scoop** (recommended):

```powershell
scoop bucket add leviath https://github.com/GEMISIS/leviath-dist.git
scoop install leviath
```

To update:

```powershell
scoop update leviath
```

**Manual install:**

1. Download `leviath-windows-x64.zip` from [GitHub Releases](https://github.com/GEMISIS/leviath-dist/releases)
2. Extract `lev.exe`
3. Add the folder containing `lev.exe` to your `PATH`

### Build from Source (any platform)

Requires [Rust](https://rustup.rs/) (stable toolchain):

```bash
cargo install --git https://github.com/GEMISIS/leviath.git --bin lev
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
- 🐛 [Report an Issue](https://github.com/GEMISIS/leviath/issues)
- 📜 [License (MIT)](https://github.com/GEMISIS/leviath/blob/main/LICENSE)
