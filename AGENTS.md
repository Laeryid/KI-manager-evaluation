# AGENTS.md — AI Agent Guidelines & Operating Procedures

> Operational specification, safety guardrails, and architectural conventions for AI coding agents (Antigravity, Claude Code, Cursor, Pi, etc.) working in the **KI-Manager Evaluation Benchmark** repository.

---

## 1. Project Mission & Architecture

This repository is a **reproducible, automated evaluation benchmark** measuring the empirical impact of the [**`ki-manager`**](https://github.com/Laeryid/KI-base) MCP server on AI coding agent performance within the mature `Textualize/rich` codebase.

### Core Agent Responsibilities
Agents working within this repository maintain, extend, and execute benchmark components:
* Docker execution harness (`harness/docker/pi-secure`).
* Benchmark task definitions, hidden evaluation suites, and reference solutions (`tasks/`).
* Orchestration scripts (`orchestrator/benchmark_runner.ps1`, `orchestrator/run_matrix.ps1`).
* Telemetry ingestion, statistical parsing, and report generation (`analysis/`).

---

## 2. Critical Invariants & Safety Guardrails

### 2.1. Strict English Language Policy (Mandatory)
> [!IMPORTANT]
> **All documents, specifications, task prompts, docstrings, code comments, logs, and git commit messages in this repository must be written in English only.**  
> Never generate Russian or non-English documentation, comments, or artifacts within the project tree.

### 2.2. Test Isolation & Anti-Cheating Invariant
> [!CAUTION]
> **Never copy validation tests (`tasks/eval_tests/`) or golden patches (`tasks/golden_patches/`) into the agent working directory (`$RunDir`) before the evaluated agent completes execution.**
* The evaluated agent inside Docker must only see standard repository tests (`rich/tests/`).
* Evaluation scripts (`test_taskX_eval.py`) are mounted or injected by the grading harness **strictly after** the agent finishes and `patch.diff` is generated.
* The test file must be cleaned up immediately following evaluation.

### 2.3. Budget Guardrails (OpenRouter API)
* Total allocated benchmark budget: **100 €** (~$108).
* **Automated Circuit Breaker:** If cumulative expenditure reaches **$80 (~74 €)**, the orchestrator must immediately halt matrix execution and persist intermediate state.
* **Staged Rollout Policy:** Expensive Tier 1 runs ($32) must never be executed without completing Stage 0 (Smoke Test, <$0.15) and Stage 1 (Tier 3 verification, ~$4.00).

### 2.4. Process Lifecycle & Deterministic Cleanup
* Every KI-mode run spawns a host `supergateway` process bound to an ephemeral TCP port.
* Termination of `supergateway` and `docker stop` / `docker rm -f` must always be wrapped in a `try ... finally` block:
  ```powershell
  try {
      # Execution logic
  } finally {
      if ($sgProcess -and -not $sgProcess.HasExited) {
          Stop-Process -Id $sgProcess.Id -Force -ErrorAction SilentlyContinue
      }
      docker rm -f $containerName 2>$null
  }
  ```
* Hard execution timeout per run: **1200 seconds (20 minutes)**.

---

## 3. Environment & Tooling Conventions

### 3.1. Host Machine (Windows)
* **Python Interpreter:** Always invoke the local virtual environment:
  * Python path: `.venv\Scripts\python.exe`
  * Pip path: `.venv\Scripts\pip.exe`
* **Shell:** PowerShell.
* **Text Search:** Use `Select-String` or `findstr` (never `grep`).
* **Directory Listing:** Use `Get-ChildItem` (never `dir`).
* **Path Portability:** Do not hardcode absolute personal paths (`C:\Users\...`). Use repository-relative paths or `$env:USERPROFILE`.

### 3.2. Evaluation Sandbox (Docker / Linux)
* Base Image: `pi-secure:latest` (Debian Bookworm, Node.js 20, Python 3).
* Container User: `agent` (UID 1000, unprivileged, no `root`/`sudo`).
* Container Flags: `--cap-drop ALL`, `--security-opt no-new-privileges`.
* Working Directory: `/app`.
* **Clean Prompt Dispatch Invariant:** To prevent command-line escaping corruption (newlines, quotation marks) across the host PowerShell / WSL boundary and avoid wrapping prompts in file attachment artifacts (`<file>`), the orchestrator writes the prompt to `$AgentDir/PROMPT.txt` and starts Pi inside the container via a launch script (`/pi-agent/launch_pi.sh`):
  ```bash
  #!/bin/bash
  exec pi -p "$(cat /pi-agent/PROMPT.txt)" "$@"
  ```
  This guarantees deterministic CLI argument transport while delivering a pristine, unwrapped prompt directly to the model.

---

## 4. A/B Testing Modes & MCP Configuration

| Mode | Flag | Environment Visible to Agent | MCP Connectivity |
| :--- | :--- | :--- | :--- |
| **Mode A** | `baseline` | Clean `rich` repository, standard tools (`read`, `write`, `edit`, `bash`) | Disabled: Container runs with `--no-mcp`. No `.ki-base/` folder. |
| **Mode B** | `ki` | `rich` repo + `.ki-base/` + `AGENTS.md` + compact MCP facade | Enabled: SSE transport to `http://host.docker.internal:<PORT>/sse` via `supergateway`. |

### Compact MCP Facade (`--tool-mode compact`)
In Mode B, only the 7 facade MCP tools are exposed to the evaluated model:
1. `ki_search` — BM25 search over Knowledge Items and ADRs (query, pagination).
2. `ki_read` — Fetch specific KI or ADR document content (by name, optional section).
3. `ki_list` — Structured manifest of all repository KIs and ADRs.
4. `ki_instructions` — Retrieve standardized agent workflow guidelines.
5. `ki_tools` — Inspect secondary tool catalogs or schemas.
6. `ki_call` — Dispatcher for read-only auxiliary tools.
7. `ki_mutate` — Dispatcher for mutating actions (blocked in benchmark mode).

---

## 5. Repository Structure

```
.
├── plan/                                 # 6 phase blueprint documents
│   ├── 00_master_plan.md                 # Master benchmark architecture
│   ├── phase_1_harness_and_docker.md     # Docker harness & Pi setup
│   ├── phase_2_repo_and_tasks.md         # Target repo commit & task specs
│   ├── phase_3_ki_base_generation.md     # Knowledge base generation & ADRs
│   ├── phase_4_orchestrator_and_runner.md# Orchestrator & runner design
│   ├── phase_5_execution_matrix.md       # Staged rollout & budget guard
│   └── phase_6_evaluation_and_reporting.md# Telemetry parser & report specs
├── harness/                              # Harness assets and container configurations
│   └── docker/                           # Dockerfile, pi-extensions, entrypoint
├── tasks/                                # Benchmark task assets
│   ├── prompts/                          # task1.txt, task2.txt, task3.txt (in English)
│   ├── eval_tests/                       # Hidden test_task1_eval.py, etc.
│   └── golden_patches/                   # Verified reference diffs
├── orchestrator/                         # Benchmark automation scripts
│   ├── benchmark_runner.ps1              # Single-run execution pipeline
│   └── run_matrix.ps1                    # Staged matrix controller
├── analysis/                             # Telemetry parsing & statistics
│   ├── evaluate_results.py               # JSONL & pytest report parser
│   └── generate_charts.py                # Visual reporting & metrics plotting
├── results/                              # (Generated) Raw session logs & summaries
├── AGENTS.md                             # This document (English only)
└── README.md                             # Public benchmark documentation (English only)
```

---

## 6. Code & Engineering Standards

* **Language Policy:** All Python docstrings, comments, type annotations, and script outputs must be in **English**.
* **Python:** 3.11+, strict type annotations (`typing`), robust CLI parsing via `argparse`.
* **PowerShell:**
  * Must include `[CmdletBinding()]` and explicit `param(...)`.
  * Strict error trapping via `$ErrorActionPreference = "Stop"` and structured `try ... catch ... finally` blocks.
* **Testing:** `pytest` with JSON report output (`--json-report`).
* **Telemetry Data:** Never fabricate or hand-modify raw benchmark logs. All summaries must be reproducibly derived from:
  * `grade.json` — Hidden pytest grading result.
  * `pi_session.jsonl` — Raw agent step-by-step turn and token telemetry.
  * `patch.diff` — Extracted git diff of the agent's changes.

---

## 7. Standard Operational Workflows

### 7.1. Executing Smoke Tests (Pipeline Validation)
```powershell
# Baseline run
.\orchestrator\benchmark_runner.ps1 -Model "google/gemini-2.5-flash" -Task "task1" -Mode "baseline" -Attempt 1

# KI-Enabled run
.\orchestrator\benchmark_runner.ps1 -Model "google/gemini-2.5-flash" -Task "task1" -Mode "ki" -Attempt 1
```

### 7.2. Ingesting Results
```powershell
.venv\Scripts\python.exe analysis\evaluate_results.py --input-dir results/ --output-dir results/summary/
```


## Knowledge Items

| File | Topic / Summary |
|------|-----------------|
| `KI_benchmark_tasks.md` | Specification of 3 evaluation tasks, hidden pytest test suites, golden reference diffs, and visual demos |
| `KI_harness_and_sandbox.md` | Docker execution sandbox (pi-secure, non-root user agent), MCP transport via supergateway SSE, and run telemetry |
| `KI_orchestrator_and_budget.md` | Automated matrix orchestration, staged rollout strategy, financial circuit breaker ($80), and timeout enforcement |
| `_OVERVIEW.ki.md` | Master benchmark architecture, A/B methodology (162 runs), model tiers, and evaluation metrics |

---

## Architecture Decision Records (ADRs)

| ID | Title | Status | Date | File |
|----|-------|--------|------|------|
| 0001 | 0001: Test Isolation & Anti-Cheating Invariant | Accepted | — | [0001-test-isolation-and-anti-cheating.md](.ki-base/decisions/0001-test-isolation-and-anti-cheating.md) |
| 0002 | 0002: Staged Rollout & Budget Circuit Breaker | Accepted | — | [0002-staged-rollout-and-circuit-breaker.md](.ki-base/decisions/0002-staged-rollout-and-circuit-breaker.md) |
| 0003 | 0003: Deterministic Supergateway & Container Lifecycle | Accepted | — | [0003-supergateway-ephemeral-port-lifecycle.md](.ki-base/decisions/0003-supergateway-ephemeral-port-lifecycle.md) |

