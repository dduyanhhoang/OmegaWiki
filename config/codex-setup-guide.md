# OmegaWiki - Codex Configuration Guide

This guide is read by `$omegawiki-setup` when running OmegaWiki in Codex.

## How Configuration Works

OmegaWiki Python tools load project API keys from the project-root `.env` file via `tools/_env.py`.
Codex authentication is handled by the Codex CLI or app and is not stored in this repository.

The repo-local Codex defaults live in `.codex/config.toml`, created from `config/codex.config.toml.example` by `setup-codex.sh`.
Repository skills live in `.agents/skills` and are loaded by Codex when you launch it from this repository or a subdirectory.
The `llm-review` MCP server uses `.venv/bin/python`, so run `setup-codex.sh` before starting Codex.

## Keys

| Key | Required? | What it enables |
|---|---:|---|
| `OPENAI_API_KEY` | Optional | API-backed tools or OpenAI-compatible Review LLM usage when configured that way |
| `SEMANTIC_SCHOLAR_API_KEY` | Optional, recommended | Citation graph, paper search, and faster literature discovery |
| `DEEPXIV_TOKEN` | Optional | Semantic paper search, TLDRs, trending papers, and richer discovery |
| `LLM_API_KEY` + `LLM_BASE_URL` + `LLM_MODEL` | Optional | Independent cross-model review through any OpenAI-compatible API |
| `ARXIV_CATEGORIES` | Optional | Category filter for daily arXiv recommendations |

## Review LLM Examples

| Provider | `LLM_BASE_URL` | Example `LLM_MODEL` |
|---|---|---|
| OpenAI | `https://api.openai.com/v1` | `gpt-5.5` |
| DeepSeek | `https://api.deepseek.com/v1` | `deepseek-chat` |
| OpenRouter | `https://openrouter.ai/api/v1` | provider model slug |
| Qwen DashScope | `https://dashscope.aliyuncs.com/compatible-mode/v1` | `qwen-max` |
| Ollama local | `http://localhost:11434/v1` | local model name |

## Verification

Run this from the repository root:

```bash
source .venv/bin/activate
python3 -c "
import os, sys
sys.path.insert(0, 'tools')
try:
    import _env
except Exception:
    pass
for k in ['OPENAI_API_KEY', 'SEMANTIC_SCHOLAR_API_KEY', 'DEEPXIV_TOKEN', 'LLM_API_KEY', 'LLM_BASE_URL', 'LLM_MODEL']:
    print(('set   ' if os.environ.get(k) else 'unset ') + k)
"
```
