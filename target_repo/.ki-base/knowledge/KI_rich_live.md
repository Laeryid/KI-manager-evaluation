<!-- last_verified: 2026-11-08 -->
# KI: Rich Core (Live Displays & Progress)

## Overview
Manages dynamic terminal updates, animations, multi-task progress bars, HTML/SVG export templates, and IPython integration. It allows real-time interactive terminal applications to refresh without screen scrolling.

## Entry Points & Public API
- `Live`: Context manager updating dynamic renderables on the terminal in place.
- `Progress`: Multi-task progress bar orchestrator managing auto-refresh threads and task progression.
- `ProgressBar`: Low-level renderable representing a single graphical progress bar.
- `Inspect`: In-depth inspection renderable formatting class attributes, methods, and docs.

## Key Components
| Class / Function | File | Purpose |
|---|---|---|
| `Live` | `rich/live.py` | Context manager handling live terminal updates via cursor movement and screen redraws |
| `LiveRender` | `rich/live_render.py` | Internal helper calculating line diffs and vertical cursor resets for live renders |
| `Progress` | `rich/progress.py` | Multi-task progress bar framework with task IDs, percentage, speeds, and ETA columns |
| `ProgressBar` | `rich/progress_bar.py` | Standalone progress meter with customizable width and completed ratio |
| `LogRender` | `rich/_log_render.py` | Formatter generating timestamped log entries and caller file links |
| `Inspect` | `rich/_inspect.py` | Object introspector presenting inheritance hierarchies, signatures, and values |
| `load_ipython_extension` | `rich/_extension.py` | Registers Rich pretty-printing and tracebacks in IPython environments |

## Testing & Verification
- Test commands: `pytest tests/test_live.py tests/test_live_render.py tests/test_progress.py tests/test_inspect.py`
- Test files: `tests/test_live.py`, `tests/test_live_render.py`, `tests/test_progress.py`, `tests/test_inspect.py`

## Non-obvious Details
- **Cursor repositioning mechanics**: `LiveRender` uses VT escape sequences (`\x1b[{n}A`) to move cursor upwards back to the top of the rendered region. If the output scrolls beyond the terminal window height, cursor restoration breaks.
- **Background auto-refresh**: `Progress` and `Live` can run a dedicated background thread for continuous refreshing at `refresh_per_second`. When calling methods across threads, tasks are synchronized via thread locks.
- **Redirecting standard streams**: `Live(redirect_stdout=True, redirect_stderr=True)` proxies `sys.stdout` and `sys.stderr` to avoid clobbering active live displays.

## Common Pitfalls
- **Standard print collision**: Invoking builtin `print()` while `Live` is running will corrupt the line buffer and cause flickers or duplicated output lines. Always use `live.console.print()`.
- **Progress task completion**: Calling `progress.advance()` beyond `total` does not auto-complete the task unless `update(completed=total)` is called explicitly.


## Related KIs
- [[KI_rich_align.md]] (via `rich/align.py`)
- [[KI_rich_align.md]] (via `rich/console.py`)
- [[KI_rich_align.md]] (via `rich/containers.py`)
- [[KI_rich_align.md]] (via `rich/control.py`)
- [[KI_rich_default.md]] (via `rich/file_proxy.py`)
- [[KI_rich_default.md]] (via `rich/highlighter.py`)
- [[KI_rich_default.md]] (via `rich/jupyter.py`)
- [[KI_rich_emoji.md]] (via `rich/color.py`)
- [[KI_rich_emoji.md]] (via `rich/color_triplet.py`)
- [[KI_rich_markdown.md]] (via `rich/measure.py`)
- [[KI_rich_markdown.md]] (via `rich/panel.py`)
- [[KI_rich_markdown.md]] (via `rich/pretty.py`)
- [[KI_rich_region.md]] (via `rich/rule.py`)
- [[KI_rich_region.md]] (via `rich/screen.py`)
- [[KI_rich_region.md]] (via `rich/segment.py`)
- [[KI_rich_region.md]] (via `rich/spinner.py`)
- [[KI_rich_region.md]] (via `rich/style.py`)
- [[KI_rich_syntax.md]] (via `rich/syntax.py`)
- [[KI_rich_syntax.md]] (via `rich/table.py`)
- [[KI_rich_syntax.md]] (via `rich/text.py`)
- [[KI_rich_syntax.md]] (via `rich/traceback.py`)

