# Power BI hand-off

The PostgreSQL cleaning layer, KPI definitions, and star schema now pass validation. This folder contains the report specification, relationship plan, DAX measures, visual theme, and Mac/browser workflow.

This directory contains:

- `model_relationships.md` — full and browser-aggregate relationship maps;
- `measures.dax` — DAX for the full PostgreSQL star schema;
- `measures_browser_aggregate.dax` — DAX for the generated browser workbook;
- `dashboard_specification.md` — four-page report plan;
- `mac_workflow.md` — browser-first and Windows fallback options;
- `control_tower_theme.json` — restrained professional colour palette.

The generated browser Excel source is `outputs/01a05dcc-9968-7a81-be26-ed89df7d1a66/control_tower_powerbi_browser_source.xlsx`.

The workbook and DAX are reconciled to the full PostgreSQL model. Building the interactive report requires a signed-in Power BI workspace and follows the exact field placements in `dashboard_specification.md`.
