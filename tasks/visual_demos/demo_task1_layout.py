"""Visual demonstration script for Task 1: Table Ratio Layout.

Generates an SVG capture of a system status dashboard featuring
a combination of fixed and flexible ratio columns.
"""

from pathlib import Path
from rich.console import Console
from rich.table import Table
from rich.panel import Panel


def render_task1_demo(output_svg_path: Path) -> None:
    output_svg_path.parent.mkdir(parents=True, exist_ok=True)
    console = Console(width=85, record=True)

    table = Table(title="Production Infrastructure Monitor", expand=True)
    table.add_column("Service", width=20, style="bold cyan")
    table.add_column("Node IP", width=18, style="dim")
    table.add_column("Status", width=10, style="green")
    table.add_column("Utilization", ratio=1, style="yellow")

    table.add_row("API Gateway", "10.0.1.12", "ACTIVE", "64% [====    ]")
    table.add_row("Auth Service", "10.0.1.18", "ACTIVE", "32% [==      ]")
    table.add_row("Payment Engine", "10.0.2.4", "ACTIVE", "89% [======  ]")
    table.add_row("Search Cluster", "10.0.3.50", "DEGRADED", "97% [========]")

    panel = Panel(table, title="Cluster Health Overview", border_style="blue")
    console.print(panel)

    console.save_svg(str(output_svg_path), title="Task 1 - Table Layout Demo")
    print(f"Saved visual demo to: {output_svg_path}")


if __name__ == "__main__":
    demo_path = Path("results/visuals/task1_layout_demo.svg")
    render_task1_demo(demo_path)
