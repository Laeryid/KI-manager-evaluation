<!-- last_verified: 2026-11-08 -->
# KI: Rich Core (Unicode Character Width Tables 5-9)

## Overview
Stores precomputed character width lookup tables for historical Unicode versions (versions 5.0.0 through 9.0.0). It provides backward-compatible East Asian Width measurements for legacy terminal environments and older OS consoles.

## Entry Points & Public API
- `load`: Internal loader resolving legacy Unicode interval tables.

## Key Components
| Class / Function | File | Purpose |
|---|---|---|
| *(lookup table)* | `rich/_unicode_data/unicode5-0-0.py` | Codepoint range intervals for Unicode 5.0.0 |
| *(lookup table)* | `rich/_unicode_data/unicode6-0-0.py` | Codepoint range intervals for Unicode 6.0.0 |
| *(lookup table)* | `rich/_unicode_data/unicode7-0-0.py` | Codepoint range intervals for Unicode 7.0.0 |
| *(lookup table)* | `rich/_unicode_data/unicode8-0-0.py` | Codepoint range intervals for Unicode 8.0.0 |
| *(lookup table)* | `rich/_unicode_data/unicode9-0-0.py` | Codepoint range intervals for Unicode 9.0.0 |

## Testing & Verification
- Test commands: `pytest tests/test_unicode_data.py tests/test_cells.py`
- Test files: `tests/test_unicode_data.py`, `tests/test_cells.py`

## Non-obvious Details
- **Legacy codepoint shifts**: Certain emoji and symbol codepoints in early Unicode releases (5.0 to 8.0) were categorized as narrow (width 1) before being reclassified as wide (width 2) in Unicode 9+.
- **Zero runtime overhead if unselected**: Only the table matching the active or requested Unicode version is imported into memory; unused versions remain unimported.

## Common Pitfalls
- **Manual editing of tables**: These tables are auto-generated from Unicode Character Database data via `tools/make_width_tables.py`; direct modifications will be overwritten upon tool runs.


## Related KIs
- [[KI_rich_align.md]] (via `rich/cells.py`)

