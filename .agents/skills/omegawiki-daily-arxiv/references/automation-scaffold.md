# Daily arXiv Automation

GitHub Actions is the unattended scheduler for `$omegawiki-daily-arxiv`. It should run
the same pipeline as a manual slash skill pass; it should not define the
feature's user-facing purpose.

## Source of Truth

- `config/daily-arxiv.yml`: durable non-secret preferences.
- `tools/daily_arxiv.py`: deterministic config, feed, evidence, and digest
  helpers.
- `$omegawiki-daily-arxiv`: LLM judgment, setup/status UX, and optional `$omegawiki-ingest`
  orchestration.
- `.github/workflows/daily-arxiv.yml`: scheduled executor.

If `config/daily-arxiv.yml` is absent, manual runs continue with inferred
defaults. `$omegawiki-daily-arxiv setup` may copy `config/daily-arxiv.yml.example`.

## Workflow Behavior

- Scheduled run: `17 0 * * *` UTC by default.
- Manual dispatch may override mode, hours, categories, caps, and e-mail.
- Inform mode prepares context, then uses the first available recommender:
  Codex Action with `OPENAI_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN`;
  otherwise an OpenAI-compatible LLM via `LLM_API_KEY` / `LLM_BASE_URL` /
  `LLM_MODEL`; otherwise a tool-ranked fallback digest.
- Auto-ingest mode fails closed unless Codex Action auth is present.
- Auto-ingest commits only staged `wiki/` and `raw/discovered/` changes
  produced by `$omegawiki-ingest`.

## Secrets

Recommendation/ingest:

- `OPENAI_API_KEY` — direct Anthropic API auth for Codex Action.
- `CLAUDE_CODE_OAUTH_TOKEN` — Codex OAuth auth for Pro/Max users; generate
  locally with `codex setup-token`. This is an alternative to
  `OPENAI_API_KEY` for Codex Action.
- `LLM_API_KEY`, `LLM_BASE_URL`, `LLM_MODEL` — optional OpenAI-compatible LLM
  for `inform` recommendation when Codex is not available.
- `LLM_FALLBACK_MODEL` — optional fallback for the OpenAI-compatible LLM.
- `SEMANTIC_SCHOLAR_API_KEY` — required for daily-cadence runs. Anonymous-tier S2 rate limits time the prepare step out against ~1000 candidates.
- `DEEPXIV_TOKEN` — required for daily-cadence runs to enable DeepXiv enrichment without anonymous-tier throttling.

These two API keys must also be exposed as workflow env vars (see *Workflow Env Exposures* below). Storing them as repo secrets is necessary but not sufficient.

SMTP delivery:

- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USER`
- `SMTP_PASSWORD`
- `SMTP_FROM`
- `DAILY_ARXIV_EMAIL_TO`

Do not store secrets in `config/daily-arxiv.yml`.

## Workflow Env Exposures

`.github/workflows/daily-arxiv.yml` must reference S2/DeepXiv secrets in the
job-level `env:` block; otherwise the runner's process environment never
receives them and the Python prepare step silently drops to anonymous mode:

```yaml
jobs:
  daily-arxiv:
    env:
      SEMANTIC_SCHOLAR_API_KEY: ${{ secrets.SEMANTIC_SCHOLAR_API_KEY }}
      DEEPXIV_TOKEN:            ${{ secrets.DEEPXIV_TOKEN }}
```

`$omegawiki-daily-arxiv setup` auto-patches the workflow to add either line if
missing — users should not have to hand-edit YAML for this. A `gh secret
set` paired with a missing exposure is the most common reason the daily
run rate-limits out (the tester sees their secrets configured and
assumes the workflow can read them), so `setup` eliminates the gap
rather than just reporting it.

## Artifacts

Each workflow run uploads:

- `resolved-config.json`
- `feed.json`
- `recommendation-context.json`
- `llm-decisions.json` when Codex ran
- `digest.md`
- `digest.json`

The Markdown digest is also appended to the GitHub Actions job summary.

## Status Checks

`$omegawiki-daily-arxiv status` should inspect:

- config presence and resolved mode/caps/categories
- workflow file presence and schedule
- whether `schedule.enabled` is false
- availability of local env vars or CI secrets when visible
- last local `.daily-arxiv/` digest if present

## Failure Behavior

- arXiv fetch failure: fail before recommendation/finalization.
- Missing SMTP secrets: fail only when e-mail is enabled.
- Empty feed or all duplicates: produce valid empty artifacts.
- External API failures: continue with degraded notes.
- Auto-ingest failures: preserve per-paper error and continue to final digest.
