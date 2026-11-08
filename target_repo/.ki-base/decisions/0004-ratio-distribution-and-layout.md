# ADR-0004: Ratio Distribution & Column Allocation

- **Status:** Accepted
- **Date:** 2026-11-08
- **Deciders:** Rich Architectural Maintainers

## Context

When rendering tables and multi-pane split layouts, columns and panels have competing size constraints: minimum width, maximum width, fixed cell counts, or proportional ratios (`ratio=1`, `ratio=2`). In collapsed views or deeply nested tables, total available space can shrink to zero or negative values, risking `ZeroDivisionError` or layout breakage.

## Decision

1. **Two-Pass Space Resolution (`rich/_ratio.py`):**  
   Space allocation via `ratio_resolve(total: int, edges: Sequence[Edge]) -> List[int]` must strictly adhere to the two-pass algorithm:
   - **Pass 1 (Fixed & Minimum Constraints):** Allocate absolute minimum widths and fixed sizes first. Subtract allocated space from `total`.
   - **Pass 2 (Proportional Ratios):** Distribute remaining space among flexible edges according to their `ratio` weights.
2. **Boundary & Zero Protection Invariants:**
   - If remaining space is zero or negative, flexible edges must receive `edge.minimum_size` (or 0) without performing division by total ratio weights.
   - Algorithms must never raise `ZeroDivisionError` on zero-weight column sets; instead, distribute space evenly or fall back to minimum sizes.
3. **Integer Conservation:**
   - The sum of resolved column widths must never exceed `total` space allocated by the parent container. Fractional remainders are distributed deterministically across flexible columns.

## Consequences

- Prevents crashes in nested or collapsed table views under narrow terminal dimensions.
- Decouples table column layout logic from split-pane `Layout` mathematics.
