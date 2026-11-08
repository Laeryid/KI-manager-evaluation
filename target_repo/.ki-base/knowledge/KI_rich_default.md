<!-- last_verified: 2026-11-08 -->
# KI: Rich Core (Layouts, Highlighters & Logging)

## Overview
Houses split-screen terminal layout panes (`Layout`), pattern regex highlighters (`Highlighter`), JSON syntax formatters, Rich logging handlers (`RichHandler`), default theme color rules, and Jupyter notebook rendering shims.

## Entry Points & Public API
- `Layout`: Divides the terminal screen into nested proportional rows and columns.
- `RichHandler`: Logging handler for Python's `logging` module printing beautiful, colored log records.
- `JSON`: Pretty-printed and syntax-highlighted JSON renderable.
- `RegexHighlighter` / `ReprHighlighter`: Base classes applying style spans via regular expression matching.

## Key Components
| Class / Function | File | Purpose |
|---|---|---|
| `Layout` | `rich/layout.py` | Hierarchical split-pane manager allocating proportions, min sizes, and visible regions |
| `RichHandler` | `rich/logging.py` | Python logging handler adding rich formatting, traceback inspection, and column alignment |
| `JSON` | `rich/json.py` | Renderable parsing JSON strings and highlighting keys, numbers, booleans, and strings |
| `Highlighter` / `RegexHighlighter` | `rich/highlighter.py` | Text stylizers highlighting IP addresses, ISO dates, URLs, and Python literals |
| `DEFAULT_STYLES` | `rich/default_styles.py` | Builtin semantic styles map (e.g. `logging.level.error`, `json.brace`, `repr.number`) |
| `FileProxy` | `rich/file_proxy.py` | File-like proxy object intercepting writes and routing them through a Console |
| `decimal` / `pick_unit_and_suffix` | `rich/filesize.py` | Human-readable byte size formatters (KB, MB, GiB, TiB) |

## Testing & Verification
- Test commands: `pytest tests/test_layout.py tests/test_logging.py tests/test_highlighter.py tests/test_json.py`
- Test files: `tests/test_layout.py`, `tests/test_logging.py`, `tests/test_highlighter.py`, `tests/test_json.py`

## Non-obvious Details
- **Tree layout resolution**: `Layout` solves spatial dimensions recursively using `ratio_resolve`. Leaf nodes without assigned renderables remain blank.
- **Log message markup parsing**: `RichHandler(markup=True)` parses Rich markup in log strings, but can unintentionally mangle percent-formatting or curly braces if users pass raw data as log messages.
- **Jupyter HTML rendering**: In Jupyter notebook kernels, `_ipython_display_` emits MIME bundle `text/html` containing styled HTML spans generated on the fly.

## Common Pitfalls
- **Unescaped brackets in log records**: When `RichHandler(markup=True)` is used, log messages containing arbitrary strings with square brackets (e.g. `[user_id]`) raise `MarkupError` unless escaped via `escape()`.
- **Negative or zero ratio layout error**: Assigning negative ratio values to a `Layout` node throws an assertion or rendering failure during bisection.


## Related KIs
- [[KI_rich_align.md]] (via `rich/align.py`)
- [[KI_rich_align.md]] (via `rich/ansi.py`)
- [[KI_rich_align.md]] (via `rich/console.py`)
- [[KI_rich_emoji.md]] (via `rich/__init__.py`)
- [[KI_rich_live.md]] (via `rich/_log_render.py`)
- [[KI_rich_markdown.md]] (via `rich/panel.py`)
- [[KI_rich_markdown.md]] (via `rich/pretty.py`)
- [[KI_rich_null.md]] (via `rich/_null_file.py`)
- [[KI_rich_null.md]] (via `rich/_ratio.py`)
- [[KI_rich_region.md]] (via `rich/region.py`)
- [[KI_rich_region.md]] (via `rich/repr.py`)
- [[KI_rich_region.md]] (via `rich/segment.py`)
- [[KI_rich_region.md]] (via `rich/style.py`)
- [[KI_rich_region.md]] (via `rich/styled.py`)
- [[KI_rich_syntax.md]] (via `rich/table.py`)
- [[KI_rich_syntax.md]] (via `rich/terminal_theme.py`)
- [[KI_rich_syntax.md]] (via `rich/text.py`)
- [[KI_rich_syntax.md]] (via `rich/traceback.py`)
- [[KI_rich_syntax.md]] (via `rich/tree.py`)

