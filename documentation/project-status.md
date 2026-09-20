# Project status and delivery milestones

## Current gate: SQL and web dashboard complete; Power BI draft in progress

| Deliverable | Status |
|---|---|
| Intel Mac local toolchain | Complete |
| Git repository and staged commit history | Complete |
| Reproducible 12-month synthetic dataset | Complete — validation passed |
| PostgreSQL database and raw imports | Complete — reconciled to source |
| Data-quality checks and cleaning | Complete — 18/18 checks passed |
| Business KPI and root-cause queries | Complete |
| Star schema | Complete — 10/10 model checks passed |
| Processed analytical exports | Complete |
| SQL learning module | Complete |
| Power BI browser-source workbook | Complete — verified |
| DAX measures, relationships, theme, and report plan | Complete |
| Power BI KPI reconciliation | Complete — 16/16 measures passed |
| Interactive web dashboard | Published on GitHub Pages |
| Power BI semantic model | Eight named tables imported; eight active relationships saved |
| Power BI DAX in service | Four measures created, reconciled to SQL and used by executive cards; remaining definitions pending |
| Interactive Power BI report | Four saved pages verified in reading view; visual and format work outstanding |
| Portfolio README and supporting documentation | Complete |

## Honest completion boundary

The SQL model and public web dashboard are complete. A Power BI workspace became available on 19 September 2026. On 20 September, the browser workbook was imported, eight relationships were saved, and four report pages were opened in reading view. Live DAX queries returned 29,873 orders, €3,221,285.15 revenue-scenario value, 62.32% on-time delivery and 688 open backlog orders. These four measures are used by the executive cards. The report is **not complete**: most planned visuals and DAX measures remain to be added, orders/revenue card formats need polishing, and real Power BI screenshots and a PDF have not been exported. SQL reconciliation of the workbook remains a separate check.

## Validation rule

The project is considered reproducible only when source validation passes, the SQL pipeline completes without error, all 18 raw-data checks match the manifest, all ten star-schema checks report zero issues, and all 16 browser-model KPI reconciliations pass.

## Delivery milestones

The original roadmap is consolidated here so the working notes have one home.

| Milestone | Completion evidence |
|---|---|
| Local environment and Git | PostgreSQL reachable; project history recorded in Git |
| Source design | Seven declared source grains, data dictionary, fixed reporting dates |
| Synthetic data | Independent validation against the controlled-defect manifest |
| Raw import | Source-to-database row counts reconciled |
| Cleaning | Eighteen source tests; corrections and eligibility rules documented |
| KPIs and analysis | Exported results agree with documented definitions |
| Star schema | Three facts, five dimensions, ten zero-issue model checks |
| Reporting | Web dashboard published; Power BI completion boundary above |
| Portfolio | Findings, recommendations, screenshots, reproduction and interview notes |
