# ADR-0003: Style Composition & ANSI Sequences

- **Status:** Accepted
- **Date:** 2026-11-08
- **Deciders:** Rich Architectural Maintainers

## Context

Styling in terminals requires combining foreground colors, background colors, links, and various text attributes (bold, italic, underline, reverse, etc.). Rich needs an immutable, high-performance styling algebra that supports cascading inheritance, markup parsing, and export to both ANSI terminals and web formats (HTML/SVG).

## Decision

1. **Immutable Style Class:**  
   The `Style` object is immutable and hashable with internal caching:
   - Attributes (bold, underline, double_underline, italic, blink, etc.) use tri-state values (`True`, `False`, `None` where `None` indicates inherit/unset).
2. **Style Composition Algebra (`+` operator):**  
   Style addition (`style1 + style2`) cascades attributes from left to right:
   - Attributes defined in `style2` override attributes in `style1` if set (`is not None`).
   - Unset attributes (`None`) in `style2` inherit values from `style1`.
3. **ANSI Sequence Mapping & Exporters:**  
   Every new style modifier must maintain synchronization across:
   - Terminal ANSI code generator: open code (e.g. `\x1b[4:2m` or `\x1b[21m`) and reset/close code.
   - Default style definitions (`rich/default_styles.py`).
   - Markup parser (`rich/markup.py`) to recognize `[modifier]...[/]`.
   - Exporters (`rich/terminal_theme.py`, `rich/_export_format.py`) for SVG and HTML rendering.

## Consequences

- Full consistency between CLI console output, HTML export, and SVG snapshots.
- Guarantees predictable cascading style resolution across nested tags.
