# SQL pipeline and cleaning rules

## Why use layers?

The pipeline separates source preservation, correction, analytics, and evidence:

```text
CSV source files
      ↓
raw schema       text values preserved as supplied
      ↓
audit schema     defects counted before any correction
      ↓
clean schema     typed, deduplicated, standardised, quality-flagged
      ↓
analytics schema KPI views and dimensional model
      ↓
audit schema     final grain, key, row-count, and value reconciliation
```

This prevents a common analytical mistake: changing data without being able to explain what changed or why.

## SQL execution order

| File | Purpose |
|---|---|
| `01_database_setup.sql` | Creates the database, four schemas, fixed reporting parameters, and pipeline audit structure. |
| `02_raw_table_setup.sql` | Creates permissive text tables so source values are not silently converted during import. |
| `03_data_import.sql` | Imports all seven CSV files and reconciles actual rows to the manifest. |
| `04_data_quality_checks.sql` | Executes 18 source-quality checks and stops if counts differ from the generator manifest. |
| `05_data_cleaning.sql` | Deduplicates, standardises categories/statuses, converts types, and assigns explicit quality flags. |
| `06_kpi_queries.sql` | Builds the reusable fulfilment and executive-KPI views. |
| `07_operations_analysis.sql` | Builds warehouse, carrier, exception, backlog, stockout, capacity, customer, and risk views. |
| `08_star_schema.sql` | Creates five conformed dimensions and three fact tables with surrogate keys. |
| `09_model_quality_checks.sql` | Runs ten zero-tolerance dimensional-model checks. |
| `10_export_results.sql` | Exports validated KPI and diagnostic outputs to `data/processed/`. |
| `11_export_powerbi_tables.sql` | Creates compact browser-reporting summaries, reconciles 16 headline measures, and exports the eight workbook sources. |
| `12_sql_learning_queries.sql` | Demonstrates core and intermediate SQL against the finished business model, including joins, CTEs, subqueries, date logic, and window functions. |

## Cleaning decisions

### Duplicates

The first source row for each business key is retained using `ROW_NUMBER()`. Extra copies are removed from the clean layer but remain visible in `raw` and `audit`.

### Status and category labels

Recognisable variants such as `delivered `, `PROCESSING`, `On-Hold`, and `Home and Kitchen` are mapped to canonical labels. Unknown values would remain flagged rather than guessed.

### Invalid quantities and dates

Negative order quantities and impossible dates are set to `NULL` in the affected analytical field and the record becomes ineligible. The original text remains in the raw table.

### Missing mappings

Clean tables retain missing or unmapped IDs with quality flags. The star schema maps them to explicit `Unknown` dimension members, while KPI measures filter according to documented eligibility rules.

### Inventory balance

Closing stock is accepted only when:

```text
opening stock + received quantity − shipped quantity = closing stock
```

Negative or unreconciled balances are flagged and excluded from inventory KPIs.

## Reconciliation results

| Table | Raw rows | Deduplicated rows | Eligible rows | Flagged rows |
|---|---:|---:|---:|---:|
| Orders | 30,060 | 30,000 | 29,873 | 127 |
| Shipments | 28,584 | 28,534 | 28,487 | 47 |
| Inventory | 262,880 | 262,800 | 262,725 | 75 |

The final fact tables contain exactly 30,000 orders, 28,534 shipments, and 262,800 inventory snapshots. All ten model checks pass with zero issues.
