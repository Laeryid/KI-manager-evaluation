"""Hidden evaluation suite for Task 1: Table Ratio Calculation and Column Collapse."""

import pytest
from rich.console import Console
from rich.table import Table
from rich._ratio import ratio_distribute, ratio_resolve, Edge


def test_ratio_distribute_zero_or_negative_total():
    """Verify ratio_distribute does not crash when total <= 0."""
    result = ratio_distribute(0, [1, 2], [1, 1])
    assert len(result) == 2
    assert result == [1, 1]

    result_neg = ratio_distribute(-5, [1, 2], [2, 2])
    assert len(result_neg) == 2
    assert result_neg == [2, 2]


def test_ratio_distribute_zero_ratios():
    """Verify ratio_distribute does not crash when sum of ratios is 0."""
    result = ratio_distribute(20, [0, 0], [5, 5])
    assert len(result) == 2
    assert result == [5, 5]

    result_none = ratio_distribute(10, [0, 0], None)
    assert len(result_none) == 2
    assert result_none == [0, 0]


def test_ratio_resolve_zero_ratios():
    """Verify ratio_resolve handles edges with 0 ratio without division by zero."""
    class MockEdge:
        size = None
        ratio = 0
        minimum_size = 2

    edges = [MockEdge(), MockEdge()]
    sizes = ratio_resolve(10, edges)
    assert len(sizes) == 2
    assert sizes == [2, 2]


def test_table_flexible_column_does_not_vanish():
    """Verify flexible columns do not vanish (width 0) in constrained tables."""
    console = Console(width=60, record=True)
    table = Table(title="Worker Dashboard", expand=True)
    table.add_column("Service", width=22)
    table.add_column("Host", width=18)
    table.add_column("Load", ratio=1)
    table.add_row("Database Primary", "db-node-01.internal", "82%")

    console.print(table)
    rendered = console.export_text()

    # The 'Load' header and '82%' cell must NOT be swallowed / 0-width
    assert "Load" in rendered, "Header 'Load' was swallowed by column collapse"
    assert "82%" in rendered, "Cell '82%' was swallowed by column collapse"
    assert "||" not in rendered, "Found collapsed zero-width column borders"


def test_table_expand_empty_cells():
    """Verify Table with expand=True and empty rows does not crash ratio distribution."""
    console = Console(width=30)
    table = Table(show_header=False, expand=True)
    table.add_column()
    table.add_column()
    table.add_row("", "")
    # Should render cleanly without raising AssertionError
    try:
        console.print(table)
    except AssertionError as exc:
        pytest.fail(f"Table rendering raised AssertionError: {exc}")
