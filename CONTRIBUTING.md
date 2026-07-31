# Contributing to leviath-dist

This repo holds Leviath's install paths: Homebrew formulae (`Formula/`), the
shared download strategy (`lib/`), Scoop manifests (`bucket/`), and the install
scripts (`install.sh`, `install.ps1`). Changes to the runtime itself belong in
[Sun-Forge-AI/leviath](https://github.com/Sun-Forge-AI/leviath) — see its
[CONTRIBUTING.md](https://github.com/Sun-Forge-AI/leviath/blob/main/CONTRIBUTING.md)
for the broader process, which applies here too.

The short version:

- `main` only takes pull requests; CI (`shellcheck`, a PowerShell AST parse, and
  `ruby -c` over the formulae) must pass, and history stays linear.
- Commits follow [Conventional Commits](https://www.conventionalcommits.org).
- Contributions are licensed under the repo's [MIT license](LICENSE); we follow
  the [Contributor Covenant](CODE_OF_CONDUCT.md).
- Anything security-sensitive (checksum verification, URL validation, PATH
  handling) gets extra scrutiny — please describe how you tested it against a
  real release, not just that CI is green.
- Security issues go through
  [private vulnerability reporting](https://github.com/Sun-Forge-AI/leviath-dist/security/advisories/new),
  never public issues.
