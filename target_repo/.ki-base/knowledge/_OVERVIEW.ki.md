<!-- last_verified: 2026-11-08 -->
# _OVERVIEW — Project Overview

**Module**: `rich` (entire project)
**Last verified**: 2026-11-08

## Overview

Rich is a Python library for rendering rich text, tables, syntax highlighting, markdown, progress bars, and formatted data to terminal output and HTML. It serves as the primary rendering engine across console applications to provide modern CLI UX.

## Subsystems & Knowledge Architecture

The codebase is partitioned into cohesive Knowledge Items (max 10 files per item):

- [[KI_rich_align.md]]: Central `Console` orchestrator, ANSI escape parsing, cells width measurement, borders, and column layouts.
- [[KI_rich_region.md]]: Low-level rendering primitives: `Segment`, `Style`, `Rule`, `Status`, `Spinner`, and screen switching.
- [[KI_rich_syntax.md]]: Data presentation components: `Table`, `Text`, `Syntax`, `Traceback`, `Tree`, and `Theme`.
- [[KI_rich_markdown.md]]: Markdown AST rendering, console `[markup]`, `Panel`, `Pretty` printing, and `Prompt` inputs.
- [[KI_rich_default.md]]: Proportional multi-pane `Layout`, regex `Highlighter`, `RichHandler` logging, and JSON formatting.
- [[KI_rich_live.md]]: Dynamic terminal updating (`Live`), multi-task progress meters (`Progress`), and IPython shims.
- [[KI_rich_emoji.md]]: Emoji parsing, `Color` color models (Standard/256/Truecolor), and Windows console backends.
- [[KI_rich_null.md]]: Internal ratio math, text wrapping routines, and Win32 low-level structures.
- [[KI_rich_unicode11-0-0.md]] & [[KI_rich_unicode5-0-0.md]]: Unicode East Asian character width lookup tables.

## Entry Points & Public API

- `rich.print`: Direct drop-in replacement for `print()` with rich markup formatting.
- `rich.inspect`: Introspective object visualizer.
- `rich.get_console()`: Global default `Console` instance accessor.
- `rich.traceback.install()`: Installs Rich exception handler for formatted stack traces.

## Testing & Verification

- Test command: `pytest tests/`

## Architecture Notes

- Follows the Rich Console Protocol (`__rich__` and `__rich_console__`).
- Renders to atomic `Segment` instances before emitting ANSI escape sequences or Win32 calls.
- Supports degradation/fallbacks for terminals without 24-bit TrueColor or Windows legacy console environments.

## Related KIs

- [[KI_rich_align.md]]
- [[KI_rich_region.md]]
- [[KI_rich_syntax.md]]
- [[KI_rich_markdown.md]]
- [[KI_rich_default.md]]
- [[KI_rich_live.md]]
- [[KI_rich_emoji.md]]
- [[KI_rich_null.md]]
- [[KI_rich_unicode11-0-0.md]]
- [[KI_rich_unicode5-0-0.md]]
