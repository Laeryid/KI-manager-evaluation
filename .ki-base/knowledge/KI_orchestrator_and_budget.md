<!-- last_verified: 2026-11-08 -->
# KI_orchestrator_and_budget — Matrix Orchestration & Budget Guardrails

**Module**: `orchestrator/`  
**Last verified**: 2026-11-08

## Overview

The orchestrator manages automated test execution across 162 evaluation runs, enforcing timeout constraints, staged rollouts, and financial circuit breakers to prevent runaway OpenRouter API costs.

## Key Components

### 1. Execution Pipelines
- **`benchmark_runner.ps1`**: Executes a single run pipeline:
  1. Creates ephemeral `$RunDir` in `temp_runs/`.
  2. Copies clean snapshot from `target_repo/`.
  3. Prepares environment (Mode A: clean; Mode B: copies `.ki-base/` and spawns `supergateway`).
  4. Launches Docker agent container with 1200s hard timeout.
  5. Extracts `patch.diff`.
  6. Injects hidden eval tests and runs pytest to generate `grade.json`.
  7. Cleans up container, processes, and temporary test files.
- **`run_matrix.ps1`**: Coordinates matrix runs by staged tiers and tracks cumulative budget expenditure.

### 2. Staged Rollout Strategy
Execution proceeds in four sequential stages:
- **Stage 0 (Smoke Test, <$0.15):** 2 runs on `google/gemini-2.5-flash` (Task 1 in Baseline & KI modes) to verify end-to-end pipeline integrity.
- **Stage 1 (Tier 3 Budget Models, ~$4.00):** Claude Haiku 5.5, GPT-5.6 Luna, Gemini 2.5 Flash.
- **Stage 2 (Tier 2 Mid-Tier Models, ~$6.00):** Gemini 3.8 Flash, DeepSeek v4.1 Flash, Qwen 2.5 Coder 32B.
- **Stage 3 (Tier 1 Flagship Models, ~$32.40):** GPT-5.6 Sol, Claude Sonnet 4, Gemini 4 Argon.

### 3. Financial Circuit Breaker & Safety Invariants
- **Total Budget:** 100 € (~$108).
- **Circuit Breaker Threshold:** $80 (~74 €).
- If cumulative OpenRouter costs reach or exceed $80, the orchestrator immediately:
  1. Terminates any running containers and processes.
  2. Persists all current telemetry and summary reports.
  3. Exits with a non-zero circuit-breaker status code.
- **Per-Run Timeout:** 1200 seconds (20 minutes). If an agent hangs or loops, the container is forcibly terminated.

## Related KIs

- [_OVERVIEW.ki.md](file:///C:/Experiments/KI-manager%20evaluation/.ki-base/knowledge/_OVERVIEW.ki.md) — Master benchmark architecture
- [KI_harness_and_sandbox.md](file:///C:/Experiments/KI-manager%20evaluation/.ki-base/knowledge/KI_harness_and_sandbox.md) — Docker container and MCP transport architecture
- [ADR-0002: Staged Rollout & Budget Circuit Breaker](file:///C:/Experiments/KI-manager%20evaluation/.ki-base/decisions/0002-staged-rollout-and-circuit-breaker.md)
