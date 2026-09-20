# Power BI report status

The PostgreSQL cleaning layer, KPI definitions, and star schema pass validation. An eight-table semantic model and a four-page draft report are saved in Power BI My workspace. This folder contains the report specification, relationship plan, DAX measures, visual theme, and Mac/browser workflow.

This directory contains:

- `model_relationships.md` — full and browser-aggregate relationship maps;
- `measures.dax` — DAX for the full PostgreSQL star schema;
- `measures_browser_aggregate.dax` — DAX for the generated browser workbook;
- `live_measures.dax` — four measures actually created and checked in the signed-in Power BI model;
- `dashboard_specification.md` — four-page report plan;
- `mac_workflow.md` — browser-first and Windows fallback options;
- `control_tower_theme.json` — restrained professional colour palette.

The [Excel source workbook](../outputs/powerbi_source/control_tower_powerbi_browser_source.xlsx) contains eight named tables.

The compact model's 16 headline calculations have been reconciled in SQL to the full PostgreSQL model. In Power BI, all eight aggregate relationships are active with many-to-one cardinality and single-direction filtering. Four live DAX measures have additionally been checked against the SQL baseline; the remaining definitions in `measures_browser_aggregate.dax` are prepared, not yet executed or verified in the service. That file uses short table names; the imported Excel tables have `tbl` prefixes, as shown in `live_measures.dax`.

The [saved report](https://app.powerbi.com/groups/me/reports/4d0f7135-3c86-4cf7-b3a4-7ad80dfea425/abc930a6a645b1be4374?experience=power-bi) has four pages: Executive Overview, Fulfilment & Delivery, Inventory Risk and Operations Diagnostics. This link requires the owner's Power BI sign-in; it is **not a public recruiter link**. The public shareable artifact remains the [GitHub Pages dashboard](https://akshayamin13.github.io/supply-chain-operations-control-tower/).

Current report boundary: the four executive cards now use validated live DAX measures from the related summary tables. `tblExecutiveKPIs` remains disconnected and is used for validation only. The orders and revenue cards still show abbreviated units (`30K` and `3.22M`); the on-time card shows `62.32%`. The remaining [specified visuals](dashboard_specification.md), formatting, full visual-level reconciliation, screenshots and PDF still need work. The saved pages were opened successfully in reading view on 20 September 2026.
