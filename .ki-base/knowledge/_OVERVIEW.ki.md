<!-- last_verified: 2026-11-08 -->
# _OVERVIEW — Project Overview

**Module**: `KI-manager evaluation` (entire benchmark repository)  
**Last verified**: 2026-11-08

## Overview

The **KI-Manager Evaluation Benchmark** is a reproducible, automated empirical evaluation suite designed to measure the impact of structured knowledge bases ([`ki-manager`](https://github.com/Laeryid/KI-base) MCP server) on autonomous AI coding agents working on the mature [`Textualize/rich`](https://github.com/Textualize/rich) codebase.

The benchmark executes an A/B matrix of 162 sandboxed runs:
- **9 Models:** Flagship (GPT-5.6 Sol, Claude Sonnet 4, Gemini 4 Argon), Mid-tier (Gemini 3.8 Flash, DeepSeek v4.1 Flash, Qwen 2.5 Coder 32B), and Budget (Claude Haiku 5.5, GPT-5.6 Luna, Gemini 2.5 Flash).
- **3 Tasks:** Cross-Module Bugfix (SWE-bench Verified), Feature Extension, and ADR Compliance.
- **2 Modes:** Mode A (Baseline, clean repo, standard tools, `--no-mcp`) vs. Mode B (KI-Enabled, pre-indexed `.ki-base/`, `AGENTS.md`, compact MCP facade via `supergateway` SSE).
- **3 Repetitions:** Statistical smoothing of non-deterministic LLM temperature noise.

## Key Components

1. **`target_repo/` (Clean Snapshot)**: Immutable baseline checkout of `Textualize/rich` with pre-indexed `.ki-base/`.
2. **`tasks/`**: Benchmark task specifications, prompts, hidden evaluation test suites, golden reference diffs, and visual demos.
3. **`harness/`**: Docker sandboxing setup (`pi-secure` image, non-root user `agent`, capability drops).
4. **`orchestrator/`**: PowerShell automation pipelines (`benchmark_runner.ps1` for individual runs, `run_matrix.ps1` for matrix execution).
5. **`analysis/`**: Python statistical evaluation, pytest JSON report ingestion, token accounting, and visualization scripts.

## Entry Points & Public API

- **Single Run Pipeline:** `.\orchestrator\benchmark_runner.ps1 -Model <id> -Task <taskX> -Mode <baseline|ki> -Attempt <N>`
- **Matrix Runner:** `.\orchestrator\run_matrix.ps1 -Stage <0|1|2|3>`
- **Results Evaluator:** `.venv\Scripts\python.exe analysis\evaluate_results.py --input-dir results/ --output-dir results/summary/`

## Testing & Verification

- **Smoke Test:** Run `benchmark_runner.ps1` on `google/gemini-2.5-flash` for Task 1 in both `baseline` and `ki` modes to verify harness integrity before spending matrix budget.
- **Grading:** Hidden evaluation scripts (`tasks/eval_tests/test_taskX_eval.py`) execute inside ephemeral sandboxes post-run to generate `grade.json`.

## Architecture Notes

- **Strict Test Isolation:** Test evaluation suites must never be exposed to the agent during execution (enforced by ADR-0001).
- **Deterministic Process Lifecycle:** Container and `supergateway` instances are guarded by strict `try ... finally` blocks (enforced by ADR-0003).
- **Budget Guardrails:** Hard stop circuit breaker halts execution if cumulative expenditure exceeds $80 (enforced by ADR-0002).

## Related KIs

- [KI_benchmark_tasks.md](file:///C:/Experiments/KI-manager%20evaluation/.ki-base/knowledge/KI_benchmark_tasks.md) — Task specs and hidden evaluation suites
- [KI_harness_and_sandbox.md](file:///C:/Experiments/KI-manager%20evaluation/.ki-base/knowledge/KI_harness_and_sandbox.md) — Docker container and MCP transport architecture
- [KI_orchestrator_and_budget.md](file:///C:/Experiments/KI-manager%20evaluation/.ki-base/knowledge/KI_orchestrator_and_budget.md) — Orchestration, budget breaker, and execution stages
- [ADR-0001: Test Isolation & Anti-Cheating Invariant](file:///C:/Experiments/KI-manager%20evaluation/.ki-base/decisions/0001-test-isolation-and-anti-cheating.md)
- [ADR-0002: Staged Rollout & Budget Circuit Breaker](file:///C:/Experiments/KI-manager%20evaluation/.ki-base/decisions/0002-staged-rollout-and-circuit-breaker.md)
- [ADR-0003: Deterministic Supergateway & Container Lifecycle](file:///C:/Experiments/KI-manager%20evaluation/.ki-base/decisions/0003-supergateway-ephemeral-port-lifecycle.md)
