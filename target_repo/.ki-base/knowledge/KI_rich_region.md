<!-- last_verified: 2026-11-08 -->
# KI: Rich Core (Segments, Styles & Atomic Primitives)

## Overview
Defines the atomic rendering primitives of Rich: `Segment` (minimal text+style tuple), `Style` (ANSI attributes container), `Rule` (horizontal dividing lines), `Status` (loading indicators with spinners), and alternate screen buffer controls (`Screen`).

## Entry Points & Public API
- `Style`: Immutable representation of text styling (color, bgcolor, bold, underline, italic, hyperlinks).
- `Segment`: Lowest-level atomic rendering token yielded by all renderables.
- `Rule`: Horizontal decorative line with optional centered title.
- `Status`: Context manager displaying a transient spinner alongside status text during long tasks.
- `auto`: Decorator automatically generating `__repr__` methods from `__rich_repr__`.

## Key Components
| Class / Function | File | Purpose |
|---|---|---|
| `Segment` | `rich/segment.py` | Atomic renderable unit containing text string, Style instance, and optional control codes |
| `Style` | `rich/style.py` | High-level style definitions supporting color blending, negation, and OSC 8 hyperlinks |
| `Rule` | `rich/rule.py` | Horizontal separator line with custom box character and title alignment |
| `Status` | `rich/status.py` | Transient loading animation utilizing `Spinner` and live console display |
| `Spinner` | `rich/spinner.py` | Animated ASCII/Unicode spinner renderable advancing frame by frame |
| `Screen` | `rich/screen.py` | Fullscreen terminal display switcher toggling alternate screen buffers |
| `auto` | `rich/repr.py` | Class decorator generating `__repr__` from `__rich_repr__` |
| `render_scope` | `rich/scope.py` | Renders a table of local/global variables with syntax styling |

## Testing & Verification
- Test commands: `pytest tests/test_segment.py tests/test_style.py tests/test_rule.py tests/test_spinner.py tests/test_status.py`
- Test files: `tests/test_segment.py`, `tests/test_style.py`, `tests/test_rule.py`, `tests/test_spinner.py`, `tests/test_status.py`

## Non-obvious Details
- **Segment splitting and line breaking**: `Segment.split_and_crop_lines` partitions segment streams into line arrays strictly respecting character cell widths and ANSI boundaries.
- **Style Bitmask & Attributes in `rich/style.py` (ADR-0003)**:
  - `STYLE_ATTRIBUTES` (L106–L126): Maps style names and short aliases (`"b"`, `"u"`, `"uu"`, `"underline2"`, `"double_underline"`, `"double-underline"`, `"du"`) to internal attribute names (`"underline2"` uses `_Bit(9)` / bitmask value 512 at L171, L189, L284).
  - `Style.__init__` (L131–L195): Accepts boolean flags (`underline`, `underline2`, `double_underline`). If `double_underline is not None: underline2 = double_underline`. Expose `@property def double_underline(self) -> bool: return bool(self.underline2)` around L290.
  - `Style.get_html_style` (L564–L605): Builds CSS rules for HTML export. At L589–L596, check `if self.underline2: append("text-decoration: underline double")` before `elif self.underline: append("text-decoration: underline")`.
  - Default style catalog in `rich/default_styles.py` (L20–L35): Maps `"underline"`, `"double_underline"`, `"double-underline"` to `Style(...)` instances so markup tags like `[double_underline]...[/]` resolve automatically.
- **Style arithmetic**: Styles can be combined using addition (`style1 + style2`), where the right-hand operand overrides attributes defined in the left-hand operand via `_attributes` and `_set_attributes` bitmasks.
- **Hyperlink support**: `Style(link="https://...")` embeds standard OSC 8 terminal hyperlinks that modern terminal emulators make clickable.

## Common Pitfalls
- **Segment mutation**: `Segment` instances should be treated as immutable. Modifying the `.text` of a segment directly breaks cell width caches.
- **Status nesting**: Attempting to run multiple nested `Status` spinners on the same console without distinct Live contexts causes display corruption.


## Related KIs
- [[KI_rich_align.md]] (via `rich/align.py`)
- [[KI_rich_align.md]] (via `rich/cells.py`)
- [[KI_rich_align.md]] (via `rich/console.py`)
- [[KI_rich_default.md]] (via `rich/highlighter.py`)
- [[KI_rich_default.md]] (via `rich/jupyter.py`)
- [[KI_rich_emoji.md]] (via `rich/__init__.py`)
- [[KI_rich_emoji.md]] (via `rich/color.py`)
- [[KI_rich_live.md]] (via `rich/_loop.py`)
- [[KI_rich_live.md]] (via `rich/live.py`)
- [[KI_rich_markdown.md]] (via `rich/measure.py`)
- [[KI_rich_markdown.md]] (via `rich/panel.py`)
- [[KI_rich_markdown.md]] (via `rich/pretty.py`)
- [[KI_rich_null.md]] (via `rich/_spinners.py`)
- [[KI_rich_syntax.md]] (via `rich/syntax.py`)
- [[KI_rich_syntax.md]] (via `rich/table.py`)
- [[KI_rich_syntax.md]] (via `rich/terminal_theme.py`)
- [[KI_rich_syntax.md]] (via `rich/text.py`)

