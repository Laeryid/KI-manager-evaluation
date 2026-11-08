# ADR-0001: Terminal Segments & Atomic Decomposition

- **Status:** Accepted
- **Date:** 2026-11-08
- **Deciders:** Rich Architectural Maintainers

## Context

Terminal emulators operate on streams of characters interspersed with ANSI escape codes for styling and cursor movement. Without a unified primitive abstraction, high-level components (tables, syntax, markdown) would have to manually track escape codes, calculate visual cell widths, and handle cross-platform line breaks, leading to exponential complexity and bugs.

## Decision

1. **Atomic Segment Primitive:**  
   Every visual element in Rich must ultimately reduce to a stream of `Segment` instances:
   ```python
   class Segment(NamedTuple):
       text: str
       style: Optional[Style] = None
       control: Optional[Sequence[ControlCode]] = None
   ```
2. **Strict Invariants:**
   - A `Segment` text piece must not contain unescaped newline characters `\n` or `\r` unless processed by `Segment.split_lines()` or `Segment.split_and_crop_lines()`.
   - Visual measurement is derived strictly from `cell_len(segment.text)` using East Asian Width Unicode tables, never raw `len(text)`.
   - Control sequences (cursor up, color palette queries) are encapsulated in the optional `control` field and take zero visual cell length.

## Consequences

- All rendering operations are stateless stream-processing pipelines.
- Layout algorithms only need to measure and slice `Segment` collections.
- Clean separation between logical layout calculation and physical terminal escape emission.
