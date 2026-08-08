# OmegaWiki - Codex Runtime Contract

This is the Codex-native project instruction file. Edit this file directly for Codex-specific behavior, or rerun ./setup-codex.sh --lang en to refresh it from the active OmegaWiki runtime contract.



## Repository Layout

- `wiki/` — product surface. `index.md` is the catalog; `log.md` is append-only; subdirs per entity kind; `wiki/graph/` is auto-generated.
- `runtime/` — contract source (schema + policy + templates). Read `runtime/schema/` and `runtime/policy/` before changing any rule.
- `raw/` — user-owned `{papers,notes,web}/` (read-only) + skill-writable `discovered/`, `tmp/`.
- `tools/` — Python helpers (`research_wiki.py` is the wiki engine; `lint.py` is the validator).

Full tree: `docs/runtime-directory-structure.en.md`.

## Link Syntax

Wikilinks: `[[slug]]`. Slugs are lowercase, hyphen-separated, no spaces.

## Hard Rules

1. `raw/{papers,notes,web}` are user-owned, read-only. Skills append only to `raw/discovered/` or `raw/tmp/`.
2. `wiki/graph/` is derived. Modify only via `tools/research_wiki.py` (`add-edge`, `add-citation`, `rebuild-*`).
3. `wiki/log.md` is append-only. Never rewrite in place.
4. Forward link → write reverse simultaneously. Rules in `runtime/schema/xref.yaml`.
5. User-facing skill flags (those listed in a skill's `argument-hint`) are user-owned. Do not invent, flip, or drop them based on repo state. If the user omitted one, use a default only when the skill documents omission behavior; otherwise ask.

## Where to look

| Need | Source |
|---|---|
| Page frontmatter fields, enums, defaults, lifecycle | `runtime/schema/entities.yaml` |
| Page body section structure                          | `runtime/templates/{kind}.md.tmpl` |
| Edge types, attributes, direction, confidence       | `runtime/schema/edges.yaml` |
| Forward → reverse link rules                         | `runtime/schema/xref.yaml` |
| Slug rule, ownership, edge storage location          | `runtime/schema/conventions.yaml` |
| Field/edge write permissions per skill               | `runtime/policy/writers.yaml` |
| Changing the contract / regen                        | `runtime/schema/`, `runtime/policy/`, `runtime/templates/` |

## Python Environment

Prefer in order: `.venv/bin/python` (`.venv/Scripts/python.exe` on Windows) → active conda env → `python3` (`python` on Windows). Tools auto-load API keys from `~/.env` and project-root `.env` via `tools/_env.py`.
