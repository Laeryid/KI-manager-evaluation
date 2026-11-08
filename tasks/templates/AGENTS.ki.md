# AI Agent Guidelines (AGENTS.md) — Textualize/rich

> Contributor and AI coding assistant guidelines for the **`Textualize/rich`** repository.

---

## 1. Project Philosophy & Architecture

Rich is a Python library for rich text and beautiful terminal formatting with zero non-standard runtime dependencies outside foundational typing and syntax parsers (`typing_extensions`, `pygments`, `markdown-it-py`).

### Core Architectural Layers
* **Console & Segments (`rich.console`, `rich.segment`)**:
  - `Console` is the primary facade coordinating measurement, rendering, and terminal emission.
  - `Segment` is the atomic rendering unit: a tuple of `(text: str, style: Optional[Style], control: Optional[ControlCode])`.
* **Render Protocol (`rich.protocol`)**:
  - Any renderable object implements `__rich_console__(self, console: Console, options: ConsoleOptions) -> RenderResult`.
  - Generator method yielding `Segment` instances or nested renderables.
  - Optional `__rich_measure__(self, console: Console, options: ConsoleOptions) -> Measurement` for computing minimum and maximum cell width.
* **Style System (`rich.style`, `rich.color`, `rich.default_styles`)**:
  - `Style` objects encapsulate ANSI SGR attributes (bold, italic, underline, color).
  - Styles are immutable and combinable (`style1 + style2` or `Style.combine([s1, s2])`).
  - Terminal themes map ANSI color names to RGB triplets.
* **Layout & Data Structures (`rich.layout`, `rich.table`, `rich.panel`, `rich._ratio`)**:
  - High-level containers (`Table`, `Panel`, `Columns`, `Tree`, `Layout`).
  - `rich._ratio` provides mathematical solvers (`ratio_distribute`, `ratio_resolve`) for dividing available terminal cells among flexible and fixed-width components.
* **Text & Markup (`rich.text`, `rich.markup`, `rich.highlighter`)**:
  - `Text` manages character spans and styling offsets.
  - `rich.markup` parses BBCode-like terminal markup (e.g., `[bold red]Alert[/]`).

---

## 2. Engineering Standards & Conventions

1. **Strict Type Annotations**:
   - Every function, method parameter, and return type must have explicit Python type annotations (`typing`).
   - Code must satisfy `mypy` without errors.
2. **Pure Python & Zero Dependency Invariant**:
   - Never introduce external third-party dependencies.
   - Maintain compatibility across supported Python versions (3.8+).
3. **Immutability & Stateless Rendering**:
   - Do not mutate passed `ConsoleOptions` instances; use `options.update(...)` to derive child constraints.
   - Never write directly to private console buffers (`console._buffer`). Always yield `Segment` instances.
4. **Code Formatting**:
   - Code adheres to standard `black` formatting and strict docstring conventions.

---

## 3. Testing & Verification Workflow

Always verify changes using targeted `pytest` commands before concluding your turn:

```bash
# Run unit tests for a specific module
pytest tests/test_table.py -v

# Run styling tests
pytest tests/test_style.py tests/test_markup.py -v

# Run the complete test suite
pytest tests/ -q
```

---

## 4. Architectural Knowledge Base (`ki-manager` MCP)

This repository is indexed by [**`ki-manager`**](https://github.com/Laeryid/KI-base), an architectural knowledge server exposing curated Knowledge Items (KIs) and Architecture Decision Records (ADRs).

### Knowledge Base Organization
- System Container: `.ki-base/`
- Directory Index: `.ki-base/DIR_INDEX.md`
- Master Architecture Overview: `.ki-base/knowledge/_OVERVIEW.ki.md`
- Knowledge Items (KIs): `.ki-base/knowledge/*.ki.md`
- Architecture Decision Records (ADRs): `.ki-base/decisions/*.md`

### Recommended Agent Workflow
1. **Explore Architecture Before Editing**:
   - Call `ki_search(query="...")` with keywords related to your task (e.g. `table ratio column`, `style attributes`, `render protocol`).
   - Call `ki_read(rel_path="...")` to read the identified KI or ADR and extract architectural constraints and invariants.
2. **Consult Available Knowledge Items & ADRs**:
   - Call `ki_list()` or `ki_instructions(document="knowledge-items")` to view the full catalog of indexed documentation.
   - Always ensure your implementation adheres to relevant ADRs.

### Knowledge Items Manifest

| File | Topic / Summary |
| :--- | :--- |
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
| `_OVERVIEW.ki.md` | Architectural master blueprint, layer boundaries, and core design invariants of the Rich library. |

### Architecture Decision Records (ADRs)

| ID | Title | Status | Date | File |
| :---: | :--- | :---: | :---: | :--- |
| **0001** | Terminal Segments & Atomic Decomposition | Accepted | 2026-11-08 | `.ki-base/decisions/0001-terminal-segments.md` |
| **0002** | Render Protocol & Component Isolation | Accepted | 2026-11-08 | `.ki-base/decisions/0002-render-protocol.md` |
| **0003** | Style Composition & ANSI Sequences | Accepted | 2026-11-08 | `.ki-base/decisions/0003-style-composition-and-ansi.md` |
| **0004** | Ratio Distribution & Column Allocation | Accepted | 2026-11-08 | `.ki-base/decisions/0004-ratio-distribution-and-layout.md` |
