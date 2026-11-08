<!-- last_verified: 2026-11-08 -->
# KI: Rich Core (Syntax, Tables, Text & Tracebacks)

## Overview
Implements high-level data presentation components: `Table` (grid formatting with auto-wrapping), `Text` (styled character spans), `Syntax` (Pygments code highlighting), `Traceback` (rich exception rendering), and `Tree` (hierarchical tree visualizations).

## Entry Points & Public API
- `Table`: Flexible 2D data grid with borders, column wrapping, and header styling.
- `Text`: Rich text container applying styles to string slices without markup overhead.
- `Syntax`: Code syntax highlighter powered by Pygments themes with line numbers.
- `Traceback`: Formatted exception hook and renderable for stack traces with syntax context.
- `Tree`: Hierarchical outline/tree view with custom branch guides and leaf nodes.
- `Theme`: Named style mapping defining cohesive terminal color palettes.

## Key Components
| Class / Function | File | Purpose |
|---|---|---|
| `Table` | `rich/table.py` | Grid container managing column widths, padding, vertical alignment, and borders |
| `Text` | `rich/text.py` | Span-based styled text representation supporting justification, wrapping, and highlights |
| `Syntax` | `rich/syntax.py` | Lexes and styles source code across languages using Pygments lexers |
| `Traceback` | `rich/traceback.py` | Exception traceback visualizer highlighting code context and local variables |
| `Tree` | `rich/tree.py` | Recursive tree diagram builder with customizable guide lines |
| `Theme` | `rich/theme.py` | Container mapping semantic style names to `Style` instances |
| `TerminalTheme` | `rich/terminal_theme.py` | Terminal color scheme definitions (ANSI 16 colors + background + foreground) |

## Testing & Verification
- Test commands: `pytest tests/test_table.py tests/test_text.py tests/test_syntax.py tests/test_traceback.py tests/test_tree.py`
- Test files: `tests/test_table.py`, `tests/test_text.py`, `tests/test_syntax.py`, `tests/test_traceback.py`, `tests/test_tree.py`

## Non-obvious Details
- **Table Width Solving in `rich/table.py` (L523–L585, ADR-0004)**:
  - `Table._calculate_column_widths(self, console: Console, options: ConsoleOptions) -> List[int]` (L523): Computes column widths (including padding, excluding border `self._extra_width`).
  - When `self.expand` is True and `columns` have `flexible` ratios (L535–L555), `flex_minimum` (L543) computes minimum widths for flexible columns (`max((column.min_width or 1) + get_padding_width(column._index), _range.minimum)`), and distributes `flexible_width = max(sum(flex_minimum), max_width - sum(fixed_widths))` via `ratio_distribute(flexible_width, ratios, flex_minimum)`.
  - When `table_width > max_width` (L556–L575), `_collapse_widths` and `ratio_reduce` shrink columns, but must enforce `min_widths = [(column.min_width or 1) + get_padding_width(column._index) for column in columns]` so flexible columns never collapse to 0 width (`max_reduce = [max(0, w - min_w) for w, min_w in zip(widths, min_widths)]` and `widths = [max(min_w, _range.maximum or 0) ...]`).
- **Traceback suppression flags**: Setting `_rich_traceback_omit = True` or `_rich_traceback_guard = True` inside a function's local scope conceals internal boilerplate frames during crashes.
- **Text span arithmetic**: When slicing or joining `Text` objects, character index spans are adjusted or split automatically to preserve original formatting.

## Common Pitfalls
- **Table row modification during iteration**: Adding rows to a `Table` while rendering it concurrently will trigger size calculation mismatches.
- **Traceback hook installation in libraries**: Calling `rich.traceback.install()` inside library code replaces global `sys.excepthook`, which can interfere with host application exception handling.


## Related KIs
- [[KI_rich_align.md]] (via `rich/align.py`)
- [[KI_rich_align.md]] (via `rich/ansi.py`)
- [[KI_rich_align.md]] (via `rich/cells.py`)
- [[KI_rich_align.md]] (via `rich/columns.py`)
- [[KI_rich_align.md]] (via `rich/console.py`)
- [[KI_rich_align.md]] (via `rich/constrain.py`)
- [[KI_rich_align.md]] (via `rich/containers.py`)
- [[KI_rich_align.md]] (via `rich/control.py`)
- [[KI_rich_default.md]] (via `rich/default_styles.py`)
- [[KI_rich_default.md]] (via `rich/highlighter.py`)
- [[KI_rich_default.md]] (via `rich/jupyter.py`)
- [[KI_rich_emoji.md]] (via `rich/__init__.py`)
- [[KI_rich_emoji.md]] (via `rich/color.py`)
- [[KI_rich_emoji.md]] (via `rich/color_triplet.py`)
- [[KI_rich_emoji.md]] (via `rich/emoji.py`)
- [[KI_rich_live.md]] (via `rich/_loop.py`)
- [[KI_rich_markdown.md]] (via `rich/markdown.py`)
- [[KI_rich_markdown.md]] (via `rich/markup.py`)
- [[KI_rich_markdown.md]] (via `rich/measure.py`)
- [[KI_rich_markdown.md]] (via `rich/padding.py`)
- [[KI_rich_markdown.md]] (via `rich/palette.py`)
- [[KI_rich_markdown.md]] (via `rich/panel.py`)
- [[KI_rich_markdown.md]] (via `rich/protocol.py`)
- [[KI_rich_null.md]] (via `rich/_pick.py`)
- [[KI_rich_null.md]] (via `rich/_ratio.py`)
- [[KI_rich_null.md]] (via `rich/_timer.py`)
- [[KI_rich_null.md]] (via `rich/_wrap.py`)
- [[KI_rich_region.md]] (via `rich/scope.py`)
- [[KI_rich_region.md]] (via `rich/segment.py`)
- [[KI_rich_region.md]] (via `rich/style.py`)
- [[KI_rich_region.md]] (via `rich/styled.py`)

