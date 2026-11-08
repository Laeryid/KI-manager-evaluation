<!-- last_verified: 2026-11-08 -->
# KI_benchmark_tasks — Benchmark Tasks & Evaluation Suites

**Module**: `tasks/`  
**Last verified**: 2026-11-08

## Overview

The benchmark evaluates autonomous AI coding agents across three distinct task categories within `Textualize/rich`. Each task tests a specific agent capability: cross-module reasoning, API/styling extension, or strict architectural adherence.

## Key Components

### 1. Task 1: Cross-Module Bugfix (SWE-bench Verified)
- **Prompt:** `tasks/prompts/task1.txt`
- **Domain:** `rich/table.py`, `rich/_ratio.py`, `rich/layout.py`
- **Problem Statement:** Fix `ZeroDivisionError` and line-wrapping corruption when calculating column ratios in collapsed nested tables with fixed-width columns.
- **Evaluation Test:** `tasks/eval_tests/test_task1_eval.py`
- **Golden Reference Diff:** `tasks/golden_patches/task1.golden.diff`
- **Visual Demo:** `tasks/visual_demos/demo_task1_layout.py`

### 2. Task 2: Feature Extension (ANSI Modifier & Exporters)
- **Prompt:** `tasks/prompts/task2.txt`
- **Domain:** `rich/style.py`, `rich/default_styles.py`, `rich/_palettes.py`, `rich/terminal_theme.py`
- **Problem Statement:** Implement the `double_underline` style attribute (`\x1b[4:2m` / `\x1b[21m`), including style addition/inheritance, markup parsing `[double_underline]text[/]`, and HTML/SVG export fidelity.
- **Evaluation Test:** `tasks/eval_tests/test_task2_eval.py`
- **Golden Reference Diff:** `tasks/golden_patches/task2.golden.diff`
- **Visual Demo:** `tasks/visual_demos/demo_task2_style.py`

### 3. Task 3: ADR Compliance (Render Protocol & Isolation)
- **Prompt:** `tasks/prompts/task3.txt`
- **Domain:** `rich/badge.py` (new component), `rich/console.py`, `rich/segment.py`
- **Problem Statement:** Implement a new `Badge` component complying strictly with ADR-0002 render protocols (`__rich_console__` yielding `Segment` stream, zero mutations to `options`, no direct writes to internal buffer).
- **Evaluation Test:** `tasks/eval_tests/test_task3_eval.py`
- **Golden Reference Diff:** `tasks/golden_patches/task3.golden.diff`
- **Visual Demo:** `tasks/visual_demos/demo_task3_badge.py`

## Invariants & Guardrails

- **Strict Test Isolation (Anti-Cheating):**  
  `test_taskX_eval.py` and `taskX.golden.diff` reside strictly outside the agent's working volume during execution. They are injected by the grading runner only after agent completion and diff extraction, and deleted immediately after grading.
- **Grading Output:**  
  The evaluation runner executes `pytest --json-report --json-report-file=grade.json test_taskX_eval.py` inside the container to assess `PASS_TO_PASS` (no regression) and `FAIL_TO_PASS` (task fix validation).

## Related KIs

- [_OVERVIEW.ki.md](file:///C:/Experiments/KI-manager%20evaluation/.ki-base/knowledge/_OVERVIEW.ki.md) — Master benchmark architecture
- [KI_harness_and_sandbox.md](file:///C:/Experiments/KI-manager%20evaluation/.ki-base/knowledge/KI_harness_and_sandbox.md) — Container execution environment
- [ADR-0001: Test Isolation & Anti-Cheating Invariant](file:///C:/Experiments/KI-manager%20evaluation/.ki-base/decisions/0001-test-isolation-and-anti-cheating.md)
