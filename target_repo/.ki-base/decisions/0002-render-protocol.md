# ADR-0002: Render Protocol & Component Isolation

- **Status:** Accepted
- **Date:** 2026-11-08
- **Deciders:** Rich Architectural Maintainers

## Context

Rich supports arbitrary nested UI components (such as Panels inside Tables inside Trees). If custom components were allowed to mutate shared rendering options or directly manipulate the `Console` buffer, rendering would become non-deterministic, thread-unsafe, and incompatible with real-time displays like `Live` and `Progress`.

## Decision

1. **Mandatory Console Protocol:**  
   All visual components must implement the public generator protocol:
   ```python
   def __rich_console__(self, console: "Console", options: "ConsoleOptions") -> "RenderResult":
       ...
       yield Segment(...)
   ```
   A component may optionally implement `__rich_measure__(self, console: "Console", options: "ConsoleOptions") -> Measurement` for dynamic sizing.

2. **Strict Component Isolation Invariants:**
   - **No Buffer Access:** Components must NEVER access or write to `console._buffer` or `console.file` directly. All output must be returned via `yield` as an iterable of `Segment` or renderable objects.
   - **Options Immutability:** The passed `options: ConsoleOptions` instance is strictly read-only. Components must never mutate its fields. To adjust constraints for child components, use `options.update(...)` which returns a fresh copy.
   - **Stateless Yielding:** Generators must be re-entrant and idempotent so that multiple render passes (e.g. measuring then rendering) produce identical results without side effects.

3. **Internal Spacing Convention for Inline Badges:**
   - In accordance with repository design conventions, inline badge components must enclose their inner text with exactly one space of padding inside the boundary caps: `"( "` + content + `" )"` for pill badges, and `"[" + " "` + content + `" ]"` for square badges.
   - Example: `Badge("DEPLOYED", pill=True, icon="★")` must yield segments rendering as `"( ★ DEPLOYED )"`. Square badges render as `"[ SYSTEM ALERT ]"`. Measurement must include the 4 cells occupied by borders and inner spaces.

## Consequences

- Components can be composed arbitrarily without side effects.
- Direct console buffer writes or mutating shared options is treated as an architectural violation and rejected in code review.
- Ensures seamless integration with `Live` displays and virtual screen buffers.
