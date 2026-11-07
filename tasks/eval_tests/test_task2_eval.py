"""Hidden evaluation suite for Task 2: First-Class double_underline Style Support."""

import pytest
from rich.console import Console
from rich.style import Style
from rich.text import Text


def test_style_init_double_underline():
    """Verify Style accepts double_underline in constructor and exposes property."""
    style = Style(double_underline=True)
    assert hasattr(style, "double_underline")
    assert style.double_underline is True
    assert style.underline2 is True


def test_style_parse_double_underline_aliases():
    """Verify Style.parse accepts double_underline, double-underline, and du."""
    s1 = Style.parse("double_underline")
    assert s1.double_underline is True

    s2 = Style.parse("double-underline")
    assert s2.double_underline is True

    s3 = Style.parse("du")
    assert s3.double_underline is True


def test_style_combination():
    """Verify combining styles preserves double_underline."""
    base = Style(bold=True, color="red")
    added = Style(double_underline=True)
    combined = base + added

    assert combined.bold is True
    assert combined.color.name == "red"
    assert combined.double_underline is True


def test_markup_double_underline():
    """Verify markup parser correctly extracts double_underline style."""
    text = Text.from_markup("This is [double_underline]emphasized[/] text")
    assert len(text.spans) == 1
    span = text.spans[0]
    assert isinstance(span.style, Style) or isinstance(span.style, str)
    style = Style.parse(span.style) if isinstance(span.style, str) else span.style
    assert style.double_underline is True


def test_html_css_export_double_underline():
    """Verify get_html_style generates CSS text-decoration: underline double."""
    style = Style(double_underline=True)
    css = style.get_html_style()
    assert "text-decoration: underline double" in css, f"Expected double underline CSS, got: '{css}'"


def test_console_svg_export_contains_double_underline():
    """Verify console SVG export includes double underline styling."""
    console = Console(record=True, width=50)
    console.print(Text.from_markup("[double_underline red]Security Advisory[/]"))
    svg_output = console.export_svg(title="Advisory")
    assert "underline double" in svg_output or "text-decoration: underline double" in svg_output
