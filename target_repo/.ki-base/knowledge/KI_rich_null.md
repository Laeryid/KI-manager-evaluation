<!-- last_verified: 2026-11-08 -->
# KI: Rich Core (Internal Utilities & Platform Adaptors)

## Overview
Provides internal mathematical routines, layout ratio solvers, text wrapping primitives, platform Win32 console structures, and base ABC protocols. It forms the low-level foundation for rendering algorithms.

## Entry Points & Public API
- `ratio_resolve`: Integer ratio distribution algorithm for flex-like sizing in layouts and tables.
- `words`: Word wrapping generator yielding split text positions without breaking ANSI tokens.
- `RichRenderable`: Abstract base class enforcing the `__rich__` rendering protocol.
- `NullFile`: Dummy writable file descriptor discarding all output.

## Key Components
| Class / Function | File | Purpose |
|---|---|---|
| `ratio_resolve` | `rich/_ratio.py` | Distributes integer space across items according to ratios and constraints |
| `words` / `divide_line` | `rich/_wrap.py` | Word and character wrapping algorithms respecting cell widths and unicode boundaries |
| `NullFile` | `rich/_null_file.py` | In-memory dummy stream implementing file protocol methods as no-ops |
| `Stack` | `rich/_stack.py` | Lightweight wrapper over list providing stack operations with peak inspection |
| `LegacyWindowsError` / Win32 structs | `rich/_win32_console.py` | ctypes definitions for Win32 Console API handles, buffers, and coordinates |
| `RichRenderable` | `rich/abc.py` | Abstract base class verifying presence of `__rich__` magic method |
| `SPINNERS` | `rich/_spinners.py` | Static catalog of animated spinner frame definitions and refresh intervals |

## Testing & Verification
- Test commands: `pytest tests/test_ratio.py tests/test_null_file.py tests/test_win32_console.py`
- Test files: `tests/test_ratio.py`, `tests/test_null_file.py`, `tests/test_win32_console.py`

## Non-obvious Details
- **Integer ratio distribution rounding**: `ratio_resolve` distributes remainder pixels based on largest fractional residuals to ensure sum of parts exactly equals total width.
- **NullFile compatibility**: Some 3rd-party libraries verify `.isatty()` or `.fileno()`; `NullFile` overrides these to gracefully avoid `io.UnsupportedOperation`.

## Common Pitfalls
- **Direct import of private utilities**: Modules prefixed with `_` (such as `_ratio`, `_wrap`, `_win32_console`) are private and subject to breaking changes across minor versions.


## Related KIs
- [[KI_rich_align.md]] (via `rich/cells.py`)
- [[KI_rich_align.md]] (via `rich/console.py`)
- [[KI_rich_emoji.md]] (via `rich/color.py`)
- [[KI_rich_live.md]] (via `rich/_loop.py`)
- [[KI_rich_markdown.md]] (via `rich/palette.py`)
- [[KI_rich_region.md]] (via `rich/style.py`)
- [[KI_rich_syntax.md]] (via `rich/text.py`)

