<!-- last_verified: 2026-11-08 -->
# KI: Rich Core (Markdown, Markup, Panels & Prompts)

## Overview
Provides markdown document parsing, console markup parsing (`[bold red]...[/]`), framed panel containers (`Panel`), recursive object pretty-printing (`Pretty`), user interactive prompts (`Prompt`), and the Rich Console Protocol definitions.

## Entry Points & Public API
- `Markdown`: Renderable converting CommonMark Markdown specifications into stylized terminal blocks.
- `Panel`: Framed container with border styles, title, and subtitle around any renderable.
- `Pretty`: Recursive data structure pretty-printer handling cyclic references and custom indentation.
- `Prompt` / `Confirm`: Interactive CLI input prompts with validation, default values, and type coercion.
- `escape`: Utility escaping square bracket markup tags in arbitrary text.

## Key Components
| Class / Function | File | Purpose |
|---|---|---|
| `Markdown` | `rich/markdown.py` | AST walker converting markdown elements (headings, code blocks, lists, blockquotes) into renderables |
| `render` / `escape` | `rich/markup.py` | Parser converting `[tag]text[/tag]` markup strings into styled `Text` spans |
| `Panel` | `rich/panel.py` | Boxed border container enclosing renderables with titles and alignment |
| `Pretty` | `rich/pretty.py` | Data structure formatter handling dicts, dataclasses, pydantic models, and recursion |
| `Prompt` / `Confirm` | `rich/prompt.py` | Interactive console prompt asking questions and verifying user answers |
| `Measurement` | `rich/measure.py` | Minimum and maximum width calculation protocol (`__rich_measure__`) |
| `Padding` | `rich/padding.py` | Surrounds a renderable with top, right, bottom, and left whitespace margins |
| `is_renderable` | `rich/protocol.py` | Introspection helper checking if an object implements Rich protocols |

## Testing & Verification
- Test commands: `pytest tests/test_markdown.py tests/test_markup.py tests/test_panel.py tests/test_pretty.py tests/test_prompt.py`
- Test files: `tests/test_markdown.py`, `tests/test_markup.py`, `tests/test_panel.py`, `tests/test_pretty.py`, `tests/test_prompt.py`

## Non-obvious Details
- **The Rich Console Protocol**: An object is renderable if it defines `__rich__() -> Renderable` or generator `__rich_console__(console, options) -> Iterable[RenderResult]`.
- **Measurement negotiation**: Containers query children using `Measurement.get(console, options, renderable)` before layout allocation to determine optimal width.
- **Markup tag stack**: `markup.py` maintains an internal tag stack. Self-closing tags or single closing slashes (`[/]`) pop the most recent active style off the stack.

## Common Pitfalls
- **Unclosed markup tags**: Forgetting to close tags like `[bold]` can lead to unexpected syntax errors (`MarkupError`) if strict parsing is enabled.
- **Prompt stdin EOF**: Calling `Prompt.ask()` in non-interactive CI environments without mocked stdin results in an unhandled `EOFError`.


## Related KIs
- [[KI_rich_align.md]] (via `rich/align.py`)
- [[KI_rich_align.md]] (via `rich/box.py`)
- [[KI_rich_align.md]] (via `rich/cells.py`)
- [[KI_rich_align.md]] (via `rich/console.py`)
- [[KI_rich_align.md]] (via `rich/containers.py`)
- [[KI_rich_default.md]] (via `rich/errors.py`)
- [[KI_rich_default.md]] (via `rich/highlighter.py`)
- [[KI_rich_default.md]] (via `rich/jupyter.py`)
- [[KI_rich_emoji.md]] (via `rich/__init__.py`)
- [[KI_rich_emoji.md]] (via `rich/_emoji_replace.py`)
- [[KI_rich_emoji.md]] (via `rich/color.py`)
- [[KI_rich_emoji.md]] (via `rich/color_triplet.py`)
- [[KI_rich_emoji.md]] (via `rich/emoji.py`)
- [[KI_rich_live.md]] (via `rich/_loop.py`)
- [[KI_rich_null.md]] (via `rich/_pick.py`)
- [[KI_rich_null.md]] (via `rich/_stack.py`)
- [[KI_rich_null.md]] (via `rich/abc.py`)
- [[KI_rich_region.md]] (via `rich/repr.py`)
- [[KI_rich_region.md]] (via `rich/rule.py`)
- [[KI_rich_region.md]] (via `rich/segment.py`)
- [[KI_rich_region.md]] (via `rich/style.py`)
- [[KI_rich_syntax.md]] (via `rich/syntax.py`)
- [[KI_rich_syntax.md]] (via `rich/table.py`)
- [[KI_rich_syntax.md]] (via `rich/text.py`)

