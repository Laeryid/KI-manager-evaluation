<!-- last_verified: 2026-11-08 -->
# KI_harness_and_sandbox — Docker Sandbox & MCP Transport

**Module**: `harness/`  
**Last verified**: 2026-11-08

## Overview

The execution harness provides a secure, deterministic runtime sandbox for evaluating AI coding agents on the target repository. It isolates the host system while allowing monitored agent interaction and SSE-based MCP tool bridging.

## Key Components

### 1. Sandbox Image (`pi-secure:latest`)
- **Base OS:** Debian Bookworm with Python 3.11+ and Node.js 20.
- **Unprivileged User:** Evaluated agents run as user `agent` (UID 1000). Root access and `sudo` are strictly disabled.
- **Security Options:**  
  Containers run with `--cap-drop ALL`, `--security-opt no-new-privileges`, and read-only host binds where applicable.
- **Working Directory:** `/app` (ephemeral mount of the test run folder).

### 2. A/B Testing Modes
- **Mode A (Baseline):**  
  - Container runs with `--no-mcp`.
  - Agent workspace has standard repository files only (no `.ki-base/`, no `AGENTS.md`).
  - Standard agent tools: `bash`, `read`, `write`, `edit`.
- **Mode B (KI-Enabled):**  
  - Target workspace receives `.ki-base/` and generated `AGENTS.md`.
  - Supergateway process is spawned on host with an ephemeral TCP port.
  - Pi container connects to `http://host.docker.internal:<PORT>/sse`.
  - Agent receives 7 facade MCP tools: `ki_search`, `ki_read`, `ki_list`, `ki_instructions`, `ki_tools`, `ki_call`, `ki_mutate`.

### 3. Telemetry Ingestion & Logs
- Every run persists:
  - `pi_session.jsonl`: Step-by-step agent turn logs, LLM model responses, token counts (input, cached, output), tool call logs.
  - `patch.diff`: The clean git diff extracted from the agent's work tree.
  - `grade.json`: Pytest execution results for hidden validation suites.

## Deterministic Lifecycle Guardrails

- `supergateway` host processes and Docker containers must be managed inside strict `try ... finally` blocks to prevent dangling processes or port conflicts (enforced by ADR-0003).
- Ephemeral ports are dynamically selected per run from range `3000-3999`.

## Related KIs

- [_OVERVIEW.ki.md](file:///C:/Experiments/KI-manager%20evaluation/.ki-base/knowledge/_OVERVIEW.ki.md) — Master benchmark architecture
- [KI_orchestrator_and_budget.md](file:///C:/Experiments/KI-manager%20evaluation/.ki-base/knowledge/KI_orchestrator_and_budget.md) — Matrix orchestration and budget safety
- [ADR-0003: Deterministic Supergateway & Container Lifecycle](file:///C:/Experiments/KI-manager%20evaluation/.ki-base/decisions/0003-supergateway-ephemeral-port-lifecycle.md)
