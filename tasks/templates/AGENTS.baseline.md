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

`pytest` and all Rich dependencies are pre-installed in the environment. Always verify your changes using targeted `pytest` commands for the relevant module(s) before concluding your turn:

```bash
# Run ratio and table layout tests
pytest tests/test_ratio.py tests/test_table.py -q

# Run styling and markup tests
pytest tests/test_style.py tests/test_markup.py -q

# Run protocol and container tests
pytest tests/test_protocol.py tests/test_panel.py -q
```
