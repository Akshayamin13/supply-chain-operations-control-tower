# Power BI report status

The PostgreSQL cleaning layer, KPI definitions, and star schema pass validation. An eight-table semantic model and a four-page draft report are saved in Power BI My workspace. This folder contains the report specification, relationship plan, DAX measures, visual theme, and Mac/browser workflow.

This directory contains:

- `model_relationships.md` — full and browser-aggregate relationship maps;
- `measures.dax` — DAX for the full PostgreSQL star schema;
- `measures_browser_aggregate.dax` — DAX for the generated browser workbook;
- `live_measures.dax` — 15 measures saved in the signed-in Power BI model, with query results for headline reconciliation;
- `dashboard_specification.md` — four-page report plan;
- `mac_workflow.md` — browser-first and Windows fallback options;
- `control_tower_theme.json` — restrained professional colour palette.

The [Excel source workbook](../outputs/powerbi_source/control_tower_powerbi_browser_source.xlsx) contains eight named tables.

The compact model's 16 headline calculations have been reconciled in SQL to the full PostgreSQL model. In Power BI, all eight aggregate relationships are active with many-to-one cardinality and single-direction filtering. Fifteen DAX measures are saved in the service; live queries checked the four executive values and nine further headline outputs against the SQL baseline. The additional two measures support those calculations. The other definitions in `measures_browser_aggregate.dax` remain prepared, not verified in the service. That file uses short table names; the imported Excel tables have `tbl` prefixes, as shown in `live_measures.dax`.

The [saved report](https://app.powerbi.com/groups/me/reports/4d0f7135-3c86-4cf7-b3a4-7ad80dfea425/abc930a6a645b1be4374?experience=power-bi) has four pages: Executive Overview, Fulfilment & Delivery, Inventory Risk and Operations Diagnostics. This link requires the owner's Power BI sign-in; it is **not a public recruiter link**. The public shareable artifact remains the [GitHub Pages dashboard](https://akshayamin13.github.io/supply-chain-operations-control-tower/).

Current report boundary: the four executive cards use validated live DAX measures from the related summary tables. The overview also charts monthly orders and warehouse on-time delivery. Fulfilment shows backlog ageing and carrier on-time delivery; inventory shows stockout snapshots and rate by category; diagnostics shows late deliveries by carrier and shipment exception rate by warehouse. `tblExecutiveKPIs` remains disconnected and is used for validation only. The orders and revenue cards still show abbreviated units (`30K` and `3.22M`); the new rate charts show decimal axes instead of percentages. The report does not yet implement all [specified visuals](dashboard_specification.md) or full visual-level reconciliation. Power BI confirmed that a four-page PDF export was ready on 20 September 2026, but the in-app browser did not yield a local PDF file for the repository. No Power BI screenshots are checked in; the public README images are from the separate React dashboard.
