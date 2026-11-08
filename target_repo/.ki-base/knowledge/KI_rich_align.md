<!-- last_verified: 2026-11-08 -->
# KI: Rich Core (Console, Alignment & Core Layouts)

## Overview
Central pipeline of Rich: houses the primary `Console` class, ANSI escape sequence decoder, cell width calculators, border box constants, and alignment/column containers. It coordinates measurement, rendering, and terminal stream emission.

## Entry Points & Public API
- `Console`: Primary interface orchestrating rendering, style resolution, capture buffers, and terminal IO.
- `Align`: Alignment wrapper centering or aligning child renderables horizontally and vertically.
- `Columns`: Flow container rendering items into flowing horizontal columns.
- `Box`: Border character definitions (e.g. `ROUNDED`, `SQUARE`, `DOUBLE`).
- `AnsiDecoder`: State machine converting raw ANSI escape strings into styled `Text` objects.

## Key Components
| Class / Function | File | Purpose |
|---|---|---|
| `Console` | `rich/console.py` | Central rendering engine managing color depth, terminal capabilities, output streams, and paging |
| `Align` | `rich/align.py` | Alignment container placing renderables left, center, or right with optional padding |
| `AnsiDecoder` | `rich/ansi.py` | State machine parsing ANSI escape codes into Rich segments |
| `Box` | `rich/box.py` | Border character sets for panels, tables, and frames |
| `cell_len` / `set_cell_size` | `rich/cells.py` | Character cell width measurement accounting for double-width CJK and zero-width characters |
| `Columns` | `rich/columns.py` | Renders a collection of items into responsive terminal columns |
| `Constrain` | `rich/constrain.py` | Limits child renderable width to a specified maximum bound |
| `Control` | `rich/control.py` | Emits raw terminal control sequences (cursor position, title changes, screen clears) |

## Testing & Verification
- Test commands: `pytest tests/test_console.py tests/test_align.py tests/test_ansi.py tests/test_box.py tests/test_columns.py`
- Test files: `tests/test_console.py`, `tests/test_align.py`, `tests/test_ansi.py`, `tests/test_box.py`, `tests/test_columns.py`

## Non-obvious Details
- **Automatic stream sniffing**: `Console` checks `COLORTERM`, `TERM`, `FORCE_COLOR`, and `NO_COLOR` upon initialization. If stdout is redirected to a pipe or file, color highlighting is stripped unless `force_terminal=True`.
- **Double-width character calculation**: `cell_len()` does not use string `len()`; it queries character codepoint tables in `_unicode_data` to properly account for wide East Asian symbols and multi-byte emojis.
- **Recording output**: `Console(record=True)` stores all rendered segments into an internal buffer, exportable via `export_text()`, `export_html()`, or `export_svg()`.

## Common Pitfalls
- **Mismatched width constraints**: Wrapping a wide table or syntax block inside `Align.center` with `width` exceeding terminal dimensions will cause line wraps that ruin horizontal centering.
- **Paging blocking**: Using `Console.pager()` captures the terminal interactively; running it inside automated or headless test runners will hang waiting for user keypresses.


## Related KIs
- [[KI_rich_default.md]] (via `rich/highlighter.py`)
- [[KI_rich_default.md]] (via `rich/json.py`)
- [[KI_rich_default.md]] (via `rich/jupyter.py`)
- [[KI_rich_emoji.md]] (via `rich/_emoji_replace.py`)
- [[KI_rich_emoji.md]] (via `rich/_unicode_data/__init__.py`)
- [[KI_rich_emoji.md]] (via `rich/_windows.py`)
- [[KI_rich_emoji.md]] (via `rich/_windows_renderer.py`)
- [[KI_rich_emoji.md]] (via `rich/color.py`)
- [[KI_rich_emoji.md]] (via `rich/emoji.py`)
- [[KI_rich_live.md]] (via `rich/_export_format.py`)
- [[KI_rich_live.md]] (via `rich/_fileno.py`)
- [[KI_rich_live.md]] (via `rich/_log_render.py`)
- [[KI_rich_live.md]] (via `rich/_loop.py`)
- [[KI_rich_live.md]] (via `rich/live.py`)
- [[KI_rich_markdown.md]] (via `rich/markup.py`)
- [[KI_rich_markdown.md]] (via `rich/measure.py`)
- [[KI_rich_markdown.md]] (via `rich/padding.py`)
- [[KI_rich_markdown.md]] (via `rich/pager.py`)
- [[KI_rich_markdown.md]] (via `rich/panel.py`)
- [[KI_rich_markdown.md]] (via `rich/pretty.py`)
- [[KI_rich_markdown.md]] (via `rich/protocol.py`)
- [[KI_rich_null.md]] (via `rich/_null_file.py`)
- [[KI_rich_null.md]] (via `rich/_win32_console.py`)
- [[KI_rich_region.md]] (via `rich/region.py`)
- [[KI_rich_region.md]] (via `rich/rule.py`)
- [[KI_rich_region.md]] (via `rich/scope.py`)
- [[KI_rich_region.md]] (via `rich/screen.py`)
- [[KI_rich_region.md]] (via `rich/segment.py`)
- [[KI_rich_region.md]] (via `rich/status.py`)
- [[KI_rich_region.md]] (via `rich/style.py`)
- [[KI_rich_region.md]] (via `rich/styled.py`)
- [[KI_rich_syntax.md]] (via `rich/table.py`)
- [[KI_rich_syntax.md]] (via `rich/terminal_theme.py`)
- [[KI_rich_syntax.md]] (via `rich/text.py`)
- [[KI_rich_syntax.md]] (via `rich/theme.py`)
- [[KI_rich_syntax.md]] (via `rich/traceback.py`)

