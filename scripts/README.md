# Scripts

| File | Purpose |
|---|---|
| `generate_data.py` | Recreates all seven synthetic source files from fixed seed `20260901`. |
| `validate_generated_data.py` | Independently validates structure, counts, keys, relationships, dates, and intended defect cases. |
| `run_pipeline.sh` | Creates the PostgreSQL database when needed and runs all 12 SQL stages with fail-fast behaviour. |
| `build_powerbi_workbook.mjs` | Builds the formatted eight-table Power BI browser workbook from the SQL exports using the Codex spreadsheet runtime. |
| `verify_powerbi_workbook.mjs` | Reopens the workbook and verifies sheet names, dimensions, tables, and formula-error absence. |

The Python generator and validator use only the standard library. The workbook builder uses the spreadsheet runtime bundled with Codex; the completed workbook is included under `outputs/` for users without that runtime.
