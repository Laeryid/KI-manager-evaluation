# ADR-0001: Test Isolation & Anti-Cheating Invariant

- **Status:** Accepted
- **Date:** 2026-11-08
- **Deciders:** Benchmark Engineering Team

## Context

To ensure the empirical validity of benchmark results across 9 LLMs, evaluated agents must never have access to ground-truth validation tests or reference patches during code generation. If test files or golden diffs leak into the container workspace (`/app`), models could overfit or copy reference solutions, corrupting scientific measurements.

## Decision

1. **Strict Physical Separation:**  
   The validation suites (`tasks/eval_tests/test_taskX_eval.py`) and reference patches (`tasks/golden_patches/*.diff`) reside exclusively on the host orchestrator file system outside the agent container volume.
2. **Post-Run Injection Protocol:**  
   Validation tests are injected into the agent's work directory strictly *after* the agent finishes execution and `patch.diff` has been generated and hashed.
3. **Immediate Post-Grading Cleanup:**  
   Once `pytest` completes and `grade.json` is persisted, injected evaluation test files must be immediately removed.

## Consequences

- Prevents prompt leaking, test-inspection shortcuts, and benchmark cheating.
- Guarantees `FAIL_TO_PASS` and `PASS_TO_PASS` metrics represent genuine zero-shot problem solving.
- Requires orchestrator pipelines to manage post-run test injection and cleanup deterministically.
