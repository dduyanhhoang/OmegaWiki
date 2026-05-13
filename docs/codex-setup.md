# OmegaWiki with Codex

OmegaWiki keeps its Claude setup intact and adds a parallel, repo-local Codex setup.

## Quick Start

```bash
chmod +x setup-codex.sh
./setup-codex.sh
codex
```

Then use the repo-scoped skills by explicit mention, for example:

```text
$omegawiki-setup
$omegawiki-init representation learning
$omegawiki-ingest raw/papers/example.pdf
$omegawiki-check
```

## What Setup Creates

`setup-codex.sh` creates these Codex-native files:

| Path | Purpose |
|---|---|
| `AGENTS.md` | Codex project instructions, generated from the active language runtime contract |
| `.codex/config.toml` | Repo-local Codex config copied from `config/codex.config.toml.example` |
| `.agents/skills/omegawiki-*` | Native Codex skills with `name` and `description` frontmatter |
| `.agents/skills/shared-references` | Shared reference files used by the native Codex skills |
| `.agents/.current-lang` | Active Codex skill language marker |

## Design Notes

Codex uses `AGENTS.md` for project instructions, `.codex/config.toml` for trusted project overrides, and `.agents/skills` for repository skills. The Codex setup follows those native locations directly.

The generated skill names use the `omegawiki-` prefix so they do not collide with built-in Codex skills or generic user skills. The former slash-command workflows are invoked as `$omegawiki-init`, `$omegawiki-ingest`, and so on.

The setup script does not modify `setup.sh`, `setup.ps1`, `CLAUDE.md`, or `.claude/`.
