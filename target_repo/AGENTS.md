# AI Agent Guidelines (AGENTS.md)

This project uses **ki-manager** (an MCP server for architectural knowledge management).

## Knowledge Base Architecture
- System container: `.ki-base/`
- Knowledge Items (KIs): strictly inside `.ki-base/knowledge/*.ki.md`
- Architecture Decision Records (ADRs): in `.ki-base/decisions/*.md` (or `decisions/`)
- Project overview & entry point: `.ki-base/knowledge/_OVERVIEW.ki.md`
- Project directory tree: `.ki-base/DIR_INDEX.md`

## Agent Operating Rules
1. **Context Before Changes**:
   - Inspect `.ki-base/knowledge/_OVERVIEW.ki.md` first.
   - Read relevant module KIs via `ki_read(rel_path="...")` or `read_know_file` before writing code.
   - List read KIs and architectural constraints in your Implementation Plan.
2. **File Safety**:
   - NEVER delete `.ki-base/knowledge/` and never save `.ki.md` files directly in `.ki-base/` root.
   - Use `ki-manager` tools (`write_know_file`, `edit_know_file`) rather than generic filesystem tools when modifying documentation.
3. **Synchronization**:
   - When modifying module logic, update the corresponding KI and run `sync_agents_md`.

## Knowledge Items
<!-- Auto-synchronized by sync_agents_md -->
| File | Topic / Summary |
|------|-----------------|
| `KI_rich_align.md` | Central pipeline of Rich: houses the primary `Console` class, ANSI escape sequence decoder, cell width calculators, border box constants, and alignment/column containers. It coordinates measurement, rendering, and terminal stream emission. |
| `KI_rich_default.md` | Houses split-screen terminal layout panes (`Layout`), pattern regex highlighters (`Highlighter`), JSON syntax formatters, Rich logging handlers (`RichHandler`), default theme color rules, and Jupyter notebook rendering shims. |
| `KI_rich_emoji.md` | Provides core emoji parsing, color representation (RGB/triplets/ANSI palettes), Windows console detection/rendering, and library top-level entry points. It translates high-level text embellishments and color palettes into terminal-safe output. |
| `KI_rich_live.md` | Manages dynamic terminal updates, animations, multi-task progress bars, HTML/SVG export templates, and IPython integration. It allows real-time interactive terminal applications to refresh without screen scrolling. |
| `KI_rich_markdown.md` | Provides markdown document parsing, console markup parsing (`[bold red]...[/]`), framed panel containers (`Panel`), recursive object pretty-printing (`Pretty`), user interactive prompts (`Prompt`), and the Rich Console Protocol definitions. |
| `KI_rich_null.md` | Provides internal mathematical routines, layout ratio solvers, text wrapping primitives, platform Win32 console structures, and base ABC protocols. It forms the low-level foundation for rendering algorithms. |
| `KI_rich_region.md` | Defines the atomic rendering primitives of Rich: `Segment` (minimal text+style tuple), `Style` (ANSI attributes container), `Rule` (horizontal dividing lines), `Status` (loading indicators with spinners), and alternate screen buffer controls (`Screen`). |
| `KI_rich_syntax.md` | Implements high-level data presentation components: `Table` (grid formatting with auto-wrapping), `Text` (styled character spans), `Syntax` (Pygments code highlighting), `Traceback` (rich exception rendering), and `Tree` (hierarchical tree visualizations). |
| `KI_rich_unicode11-0-0.md` | Contains precomputed Unicode East Asian Width lookup tables for modern Unicode specifications (versions 11.0.0 through 17.0.0, plus 4.1.0). These tables determine whether individual Unicode codepoints occupy 0, 1, or 2 terminal character cells. |
| `KI_rich_unicode5-0-0.md` | Stores precomputed character width lookup tables for historical Unicode versions (versions 5.0.0 through 9.0.0). It provides backward-compatible East Asian Width measurements for legacy terminal environments and older OS consoles. |
| `_OVERVIEW.ki.md` | Project overview |

## Architecture Decision Records (ADRs)

| ID | Title | Status | Date | File |
|----|-------|--------|------|------|
| 0001 | 0001: Terminal Segments & Atomic Decomposition | Accepted | 2026-11-08 | [0001-terminal-segments.md](.ki-base/decisions/0001-terminal-segments.md) |
| 0002 | 0002: Render Protocol & Component Isolation | Accepted | 2026-11-08 | [0002-render-protocol.md](.ki-base/decisions/0002-render-protocol.md) |
| 0003 | 0003: Style Composition & ANSI Sequences | Accepted | 2026-11-08 | [0003-style-composition-and-ansi.md](.ki-base/decisions/0003-style-composition-and-ansi.md) |
| 0004 | 0004: Ratio Distribution & Column Allocation | Accepted | 2026-11-08 | [0004-ratio-distribution-and-layout.md](.ki-base/decisions/0004-ratio-distribution-and-layout.md) |
