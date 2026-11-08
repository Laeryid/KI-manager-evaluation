<!-- last_verified: 2026-11-08 -->
# KI: Rich Core (Emoji, Color & Windows Backend)

## Overview
Provides core emoji parsing, color representation (RGB/triplets/ANSI palettes), Windows console detection/rendering, and library top-level entry points. It translates high-level text embellishments and color palettes into terminal-safe output.

## Entry Points & Public API
- `rich.print`: Top-level convenience wrapper printing formatted renderables to global console.
- `rich.inspect`: Introspection utility inspecting live Python objects.
- `Emoji`: Renderable converting `:emoji_name:` shortcodes into Unicode glyphs.
- `Color`: Abstraction supporting Standard (8-bit), 256-color, and Truecolor (24-bit RGB) palettes.
- `ColorTriplet`: Named tuple representing red, green, and blue 8-bit components.

## Key Components
| Class / Function | File | Purpose |
|---|---|---|
| `Emoji` | `rich/emoji.py` | Renderable and parser replacing emoji codes with unicode characters |
| `_emoji_replace` | `rich/_emoji_replace.py` | Fast regex-based substitution using `_EMOJI` mapping table |
| `Color` | `rich/color.py` | Universal color container handling hex, rgb, standard names, and color downgrade |
| `ColorTriplet` | `rich/color_triplet.py` | Red/green/blue 8-bit color representation with hex and blending utilities |
| `WindowsConsoleFeatures` | `rich/_windows.py` | Detection helper determining Windows Terminal, VT100 support, or legacy conhost |
| `legacy_windows_render` | `rich/_windows_renderer.py` | Fallback renderer writing styled segments via Win32 Console API calls |
| `get_console` | `rich/__init__.py` | Global singleton accessor for the default Console instance |

## Testing & Verification
- Test commands: `pytest tests/test_emoji.py tests/test_color.py tests/test_color_triplet.py tests/test_windows_renderer.py`
- Test files: `tests/test_emoji.py`, `tests/test_color.py`, `tests/test_color_triplet.py`, `tests/test_windows_renderer.py`

## Non-obvious Details
- **Windows legacy degradation**: If Windows VT processing is unsupported, `legacy_windows_render` intercepts segments and translates styles into Win32 `SetConsoleTextAttribute` calls.
- **Emoji variant selector**: Rich appends variation selector-16 (`\uFE0F`) to certain emoji shortcodes to force graphic emoji presentation rather than text glyphs.
- **Color downgrading**: When a 24-bit Truecolor is emitted to a 256-color or standard 16-color terminal, `Color.downgrade` calculates Euclidean distances in RGB space to pick the nearest color match.

## Common Pitfalls
- **Unknown emoji lookup**: Referencing an invalid `:shortcode:` raises `NoEmoji` unless configured with `Emoji.replace(text, default="...")`.
- **ANSI vs Win32 cursor artifacts**: Direct console manipulation during legacy Windows rendering may leave trailing style attributes on subsequent terminal lines.


## Related KIs
- [[KI_rich_align.md]] (via `rich/cells.py`)
- [[KI_rich_align.md]] (via `rich/columns.py`)
- [[KI_rich_align.md]] (via `rich/console.py`)
- [[KI_rich_default.md]] (via `rich/jupyter.py`)
- [[KI_rich_live.md]] (via `rich/_extension.py`)
- [[KI_rich_live.md]] (via `rich/_inspect.py`)
- [[KI_rich_null.md]] (via `rich/_palettes.py`)
- [[KI_rich_null.md]] (via `rich/_win32_console.py`)
- [[KI_rich_region.md]] (via `rich/repr.py`)
- [[KI_rich_region.md]] (via `rich/segment.py`)
- [[KI_rich_region.md]] (via `rich/style.py`)
- [[KI_rich_syntax.md]] (via `rich/_unicode_data/_versions.py`)
- [[KI_rich_syntax.md]] (via `rich/table.py`)
- [[KI_rich_syntax.md]] (via `rich/terminal_theme.py`)
- [[KI_rich_syntax.md]] (via `rich/text.py`)

