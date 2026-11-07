"""Visual demonstration script for Task 2: double_underline Typography Showcase.

Generates an SVG capture demonstrating single underline vs double_underline
typography across multiple styles and colors.
"""

from pathlib import Path
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.text import Text


def render_task2_demo(output_svg_path: Path) -> None:
    output_svg_path.parent.mkdir(parents=True, exist_ok=True)
    console = Console(width=80, record=True)

    table = Table(title="Rich Typography & ANSI Modifier Matrix", expand=True)
    table.add_column("Style Name", style="bold white", width=22)
    table.add_column("Rendered Sample", ratio=1)
    table.add_column("ANSI / CSS Target", style="dim", width=25)

    table.add_row(
        "Standard Underline",
        Text.from_markup("[underline cyan]The quick brown fox jumps over the lazy dog[/]"),
        "SGR 4 / underline",
    )
    table.add_row(
        "Double Underline",
        Text.from_markup("[double_underline yellow]The quick brown fox jumps over the lazy dog[/]"),
        "SGR 21 / underline double",
    )
    table.add_row(
        "Combined Bold + Double",
        Text.from_markup("[bold double_underline magenta]CRITICAL COMPLIANCE NOTICE - ACTION REQUIRED[/]"),
        "SGR 1;21 / bold + double",
    )
    table.add_row(
        "Nested Tag Styles",
        Text.from_markup("Standard [u green]Single[/] vs [double_underline red]Double[/] in one sentence"),
        "Mixed ANSI hierarchy",
    )

    panel = Panel(
        table,
        title="[bold blue]Feature Showcase: double_underline[/]",
        subtitle="[dim]Rendered with Rich 14.3+ SVG Engine[/]",
        border_style="cyan",
    )
    console.print(panel)

    console.save_svg(str(output_svg_path), title="Task 2 - Style Demo")
    print(f"Saved visual demo to: {output_svg_path}")


if __name__ == "__main__":
    demo_path = Path("results/visuals/task2_style_demo.svg")
    render_task2_demo(demo_path)
