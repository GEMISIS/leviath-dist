# Security Policy

This repo distributes Leviath — the Homebrew tap, Scoop bucket, and install
scripts. The runtime itself, its threat model, and the full security policy live
in the main repo:
[Sun-Forge-AI/leviath/SECURITY.md](https://github.com/Sun-Forge-AI/leviath/blob/main/SECURITY.md).

## Reporting a vulnerability

Please report vulnerabilities in the installers, formulae, or manifests privately
via GitHub's
[private vulnerability reporting](https://github.com/Sun-Forge-AI/leviath-dist/security/advisories/new)
— never in a public issue. Reports about the `lev` runtime itself go to the
[main repo's advisory form](https://github.com/Sun-Forge-AI/leviath/security/advisories/new).

## What the installers guarantee

Every install path (formulae, manifests, both scripts) downloads over HTTPS only
and verifies the asset against the `SHA256SUMS` published in the same release
before anything is unpacked, refusing to install on any mismatch or missing
entry. The checksum comes from the same release as the asset, so it does not
defend against an attacker who can rewrite a whole release — for that, releases
carry GitHub build-provenance attestations you can verify manually:

```bash
gh attestation verify leviath-linux-x64.tar.gz --repo Sun-Forge-AI/leviath
```
