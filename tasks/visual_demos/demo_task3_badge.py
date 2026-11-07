"""Visual demonstration script for Task 3: Embeddable Badge Component.

Generates an SVG capture demonstrating Badge components with custom icons,
pill caps, and color themes embedded in a Table and a status Panel.
"""

from pathlib import Path
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.badge import Badge


def render_task3_demo(output_svg_path: Path) -> None:
    output_svg_path.parent.mkdir(parents=True, exist_ok=True)
    console = Console(width=85, record=True)

    table = Table(title="Cloud Cluster Services & Workloads", expand=True)
    table.add_column("Microservice", style="bold white", width=22)
    table.add_column("Environment", width=16)
    table.add_column("Health Status", width=18)
    table.add_column("Deployment Type", width=20)

    table.add_row(
        "auth-orchestrator",
        "Production-US",
        Badge("ONLINE", style="bold white on dark_green", pill=True, icon="●"),
        Badge("Kubernetes", style="cyan", pill=False),
    )
    table.add_row(
        "billing-engine",
        "Production-EU",
        Badge("STABLE", style="bold white on green", pill=True, icon="●"),
        Badge("Serverless", style="blue", pill=False),
    )
    table.add_row(
        "search-indexer",
        "Staging-APAC",
        Badge("DEGRADED", style="bold black on yellow", pill=True, icon="▲"),
        Badge("StatefulSet", style="magenta", pill=False),
    )
    table.add_row(
        "analytics-pipeline",
        "Canary-Global",
        Badge("CRITICAL", style="bold white on red", pill=True, icon="✖"),
        Badge("DaemonSet", style="cyan", pill=False),
    )

    panel = Panel(
        table,
        title="[bold cyan]Rich Component Showcase: Badge (ADR-0002)[/]",
        subtitle="[dim]Streamed Segments with Zero Buffer Side-Effects[/]",
        border_style="bright_blue",
    )
    console.print(panel)

    console.save_svg(str(output_svg_path), title="Task 3 - Badge Component Demo")
    print(f"Saved visual demo to: {output_svg_path}")


if __name__ == "__main__":
    demo_path = Path("results/visuals/task3_badge_demo.svg")
    render_task3_demo(demo_path)
