# Project status

## Current gate: SQL and analytical handoff complete

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
| Interactive Power BI report | Requires a signed-in Power BI workspace |
| Portfolio README and supporting documentation | Complete |

## Honest completion boundary

The local, reproducible analytics project is complete. Power BI Desktop cannot run natively on this Intel Mac, and this local build does not have authority to create content inside the user's Microsoft tenant. The repository therefore provides the verified workbook, DAX, relationship map, theme, and exact page-building instructions needed to finish the visual report in the Power BI service.

## Validation rule

The project is considered reproducible only when source validation passes, the SQL pipeline completes without error, all 18 raw-data checks match the manifest, all ten star-schema checks report zero issues, and all 16 browser-model KPI reconciliations pass.
