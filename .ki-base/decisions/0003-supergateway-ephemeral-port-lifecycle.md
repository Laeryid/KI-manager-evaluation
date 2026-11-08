# ADR-0003: Deterministic Supergateway & Container Lifecycle

- **Status:** Accepted
- **Date:** 2026-11-08
- **Deciders:** Benchmark Engineering Team

## Context

In Mode B (KI-Enabled), the host Windows orchestrator executes a background `supergateway` process providing SSE transport for `ki-manager` MCP tools to the Docker container. If a run crashes, times out, or receives an interrupt, dangling processes or zombie containers could hold TCP ports open and cause subsequent runs to fail.

## Decision

1. **Guaranteed Cleanup via `try ... finally`:**  
   Every container execution and background gateway process must be wrapped in structured error trapping with deterministic teardown:
   ```powershell
   try {
       # Launch supergateway & Docker container
       # Wait for run completion or timeout (1200s)
   } finally {
       if ($sgProcess -and -not $sgProcess.HasExited) {
           Stop-Process -Id $sgProcess.Id -Force -ErrorAction SilentlyContinue
       }
       docker rm -f $containerName 2>$null
   }
   ```
2. **Ephemeral Port Allocation:**  
   Each run dynamically selects an available TCP port in the range `3000-3999` rather than hardcoding a static port, preventing collision between consecutive runs.

## Consequences

- Eliminates port conflicts and dangling host processes across automated batch runs.
- Ensures clean Docker state before every run attempt.
