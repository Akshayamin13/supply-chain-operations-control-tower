# Power BI hand-off

The PostgreSQL cleaning layer, KPI definitions, and star schema now pass validation. This folder contains the report specification, relationship plan, DAX measures, visual theme, and Mac/browser workflow.

This directory contains:

- `model_relationships.md` — full and browser-aggregate relationship maps;
- `measures.dax` — DAX for the full PostgreSQL star schema;
- `measures_browser_aggregate.dax` — DAX for the generated browser workbook;
- `dashboard_specification.md` — four-page report plan;
- `mac_workflow.md` — browser-first and Windows fallback options;
- `control_tower_theme.json` — restrained professional colour palette.

The [Excel source workbook](../outputs/powerbi_source/control_tower_powerbi_browser_source.xlsx) contains eight named tables.

The compact model's 16 headline calculations have been reconciled in SQL to the full PostgreSQL model. The DAX definitions still need to be executed and checked in Power BI. Building the interactive report requires a signed-in workspace; [the specification](dashboard_specification.md) distinguishes the compact workbook's supported visuals from the additional detail required for a full report.
