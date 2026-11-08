# ADR-0002: Staged Rollout & Budget Circuit Breaker

- **Status:** Accepted
- **Date:** 2026-11-08
- **Deciders:** Benchmark Engineering Team

## Context

Running 162 automated agent sessions across 9 LLMs against OpenRouter APIs carries financial risks if a model gets stuck in an infinite retry loop or generates excessive exploratory tokens. The benchmark has a strict total budget limit of 100 € (~$108), with an estimated matrix cost of ~$54–$58.

## Decision

1. **Mandatory Staged Rollout:**  
   Matrix execution must strictly progress through sequential stages:
   - **Stage 0 (Smoke Test, <$0.15):** 2 validation runs (`gemini-2.5-flash`, Task 1, Mode A & Mode B).
   - **Stage 1 (Tier 3 Budget, ~$4.00):** Claude Haiku 5.5, GPT-5.6 Luna, Gemini 2.5 Flash.
   - **Stage 2 (Tier 2 Mid-Tier, ~$6.00):** Gemini 3.8 Flash, DeepSeek v4.1 Flash, Qwen 2.5 Coder 32B.
   - **Stage 3 (Tier 1 Flagship, ~$32.40):** GPT-5.6 Sol, Claude Sonnet 4, Gemini 4 Argon.
   Stage 3 must never be executed unless Stages 0, 1, and 2 complete with zero harness infrastructure failures.
2. **Automated Circuit Breaker:**  
   If cumulative expenditure reaches $80 (~74 €), the orchestrator immediately halts matrix processing, records intermediate progress, and raises an alert.
3. **Per-Run Hard Timeout:**  
   Every run enforces a hard 1200-second (20-minute) execution ceiling.

## Consequences

- Completely protects benchmark financial limits against runaway loops and API bugs.
- Guarantees intermediate telemetry is persisted even in the event of an early circuit breaker trigger.
