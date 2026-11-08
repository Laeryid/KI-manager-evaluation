# KI-Manager Evaluation Benchmark — Consolidated Report

> **Total Evaluated Cost:** `$3.9205 USD`  
> **Generated:** `2026-11-08`

## 1. Summary Performance Matrix

| Model | Mode | Overall Pass % | Task 1 (Bugfix) | Task 2 (Feature) | Task 3 (ADR) | Avg Turns | 1st Edit Turn | Avg Cost / Run | Cost / Solved | KI Calls | Exploration Calls |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `anthropic/claude-haiku-5.5` | baseline | 55.6% | 0.0% | 66.7% | 100.0% | 18.0 | 7.1 | `$0.0144` | `$0.0259` | 0.0 | 0.4 |
| `anthropic/claude-haiku-5.5` | **ki** | **66.7%** | 0.0% | 100.0% | 100.0% | 14.6 | 6.6 | `$0.0144` | `$0.0216` | 1.2 | 2.0 |
| `google/gemini-2.5-flash` | baseline | 11.1% | 0.0% | 0.0% | 33.3% | 30.0 | 2.8 | `$0.2066` | `$1.8598` | 0.0 | 9.7 |
| `google/gemini-2.5-flash` | **ki** | **33.3%** | 100.0% | 0.0% | 0.0% | 22.6 | 4.6 | `$0.1531` | `$0.4592` | 2.9 | 5.6 |
| `openai/gpt-5.6-luna` | baseline | 100.0% | 100.0% | 100.0% | 100.0% | 15.1 | 5.4 | `$0.0198` | `$0.0198` | 0.0 | 12.0 |
| `openai/gpt-5.6-luna` | **ki** | **77.8%** | 33.3% | 100.0% | 100.0% | 18.4 | 7.0 | `$0.0274` | `$0.0352` | 4.9 | 12.1 |

## 2. Key Hypotheses Verification

1. **Time-to-First-Edit Efficiency:** Comparing turns taken before first code modification in Baseline vs KI-mode.
2. **Exploration Waste Reduction:** Quantifying reduction in blind `grep`/`find`/`read` calls through indexed BM25 search (`ki_search`).
3. **ADR Compliance Rate:** Verifying zero architectural violations on Task 3 (`rich/badge.py`).
