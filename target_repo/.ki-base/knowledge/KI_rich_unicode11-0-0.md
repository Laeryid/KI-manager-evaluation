<!-- last_verified: 2026-11-08 -->
# KI: Rich Core (Unicode Character Width Tables 11-17)

## Overview
Contains precomputed Unicode East Asian Width lookup tables for modern Unicode specifications (versions 11.0.0 through 17.0.0, plus 4.1.0). These tables determine whether individual Unicode codepoints occupy 0, 1, or 2 terminal character cells.

## Entry Points & Public API
- `load`: Module-level function in `rich._unicode_data` retrieving the cell width mapping table for an active Unicode version.

## Key Components
| Class / Function | File | Purpose |
|---|---|---|
| `load` | `rich/_unicode_data/__init__.py` | Loads the cell width interval tree or binary search table for the selected Unicode version |
| *(lookup table)* | `rich/_unicode_data/unicode11-0-0.py` | Codepoint range intervals for Unicode 11.0.0 |
| *(lookup table)* | `rich/_unicode_data/unicode12-0-0.py` | Codepoint range intervals for Unicode 12.0.0 |
| *(lookup table)* | `rich/_unicode_data/unicode13-0-0.py` | Codepoint range intervals for Unicode 13.0.0 |
| *(lookup table)* | `rich/_unicode_data/unicode14-0-0.py` | Codepoint range intervals for Unicode 14.0.0 |
| *(lookup table)* | `rich/_unicode_data/unicode15-0-0.py` | Codepoint range intervals for Unicode 15.0.0 |
| *(lookup table)* | `rich/_unicode_data/unicode16-0-0.py` | Codepoint range intervals for Unicode 16.0.0 |
| *(lookup table)* | `rich/_unicode_data/unicode17-0-0.py` | Codepoint range intervals for Unicode 17.0.0 |

## Testing & Verification
- Test commands: `pytest tests/test_unicode_data.py tests/test_cells.py`
- Test files: `tests/test_unicode_data.py`, `tests/test_cells.py`

## Non-obvious Details
- **Binary interval search**: Lookup is implemented as binary search over sorted integer tuples of `(start_codepoint, end_codepoint, cell_width)` to minimize memory footprint while enabling O(log N) lookup.
- **Environment override**: The active unicode table version can be forced via the `UNICODE_VERSION` environment variable.

## Common Pitfalls
- **Terminal font disparity**: Even if Rich accurately computes a glyph as width 2 according to Unicode 15.0, older terminal emulators using outdated Unicode tables may still render it as width 1, causing character overlap.


## Related KIs
- [[KI_rich_align.md]] (via `rich/cells.py`)

