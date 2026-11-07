"""Hidden evaluation suite for Task 3: ADR-0002 Compliance and Badge UI Component."""

import ast
from pathlib import Path
import pytest

from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.measure import Measurement


def test_adr0002_ast_compliance():
    """Verify rich/badge.py strictly obeys ADR-0002 architectural constraints."""
    candidates = [
        Path(__file__).resolve().parent.parent / "rich" / "badge.py",
        Path("rich/badge.py"),
        Path("target_repo/rich/badge.py"),
    ]
    badge_file = next((p for p in candidates if p.exists()), None)
    assert badge_file is not None and badge_file.exists(), "rich/badge.py was not created"

    source = badge_file.read_text(encoding="utf-8")
    tree = ast.parse(source)

    has_rich_console = False
    has_rich_measure = False

    for node in ast.walk(tree):
        # Verify prohibited access to private buffer
        if isinstance(node, ast.Attribute):
            assert node.attr != "_buffer", (
                "ADR-0002 Violation: Direct access to console._buffer is strictly prohibited."
            )
        # Verify required protocols
        if isinstance(node, ast.FunctionDef):
            if node.name == "__rich_console__":
                has_rich_console = True
            elif node.name == "__rich_measure__":
                has_rich_measure = True

    assert has_rich_console, "ADR-0002 Violation: Badge must implement __rich_console__"
    assert has_rich_measure, "Badge must implement __rich_measure__"


def test_badge_import_and_init():
    """Verify Badge can be imported from rich and initialized."""
    from rich import Badge
    from rich.badge import Badge as DirectBadge

    assert Badge is DirectBadge

    b1 = Badge("SUCCESS", style="bold green", pill=True, icon="✔")
    assert b1.text == "SUCCESS"
    assert b1.icon == "✔"
    assert b1.pill is True


def test_badge_standalone_render():
    """Verify Badge renders standalone to console."""
    from rich.badge import Badge

    console = Console(record=True, width=40)
    badge = Badge("DEPLOYED", style="bold white on green", pill=True, icon="★")
    console.print(badge)

    rendered = console.export_text()
    assert "DEPLOYED" in rendered
    assert "★" in rendered
    assert "(" in rendered and ")" in rendered


def test_badge_embedded_in_table():
    """Verify Badge embeds seamlessly inside Table cells."""
    from rich.badge import Badge

    console = Console(record=True, width=60)
    table = Table(title="Services")
    table.add_column("Service")
    table.add_column("Health")

    table.add_row("Payment Gateway", Badge("HEALTHY", style="green", icon="●"))
    table.add_row("Auth Server", Badge("OFFLINE", style="red", icon="■"))

    console.print(table)
    rendered = console.export_text()

    assert "Payment Gateway" in rendered
    assert "HEALTHY" in rendered
    assert "OFFLINE" in rendered


def test_badge_embedded_in_panel():
    """Verify Badge embeds cleanly inside a Panel."""
    from rich.badge import Badge

    console = Console(record=True, width=50)
    panel = Panel(Badge("SYSTEM ALERT", style="bold red", pill=False), title="Notice")
    console.print(panel)

    rendered = console.export_text()
    assert "SYSTEM ALERT" in rendered
    assert "[" in rendered and "]" in rendered


def test_badge_measurement():
    """Verify Badge measurement accurately reflects width."""
    from rich.badge import Badge

    console = Console(width=80)
    badge = Badge("INFO", pill=True, icon="ℹ")
    measurement = Measurement.get(console, console.options, badge)

    assert measurement.minimum > 0
    assert measurement.maximum >= measurement.minimum
