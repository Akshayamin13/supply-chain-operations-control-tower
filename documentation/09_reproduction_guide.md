# Reproduction guide

## Prerequisites

- PostgreSQL 16 or a compatible recent PostgreSQL release
- Python 3.9 or later
- Git
- A local PostgreSQL user permitted to create a database

No third-party Python package is required for data generation or validation.

## 1. Generate and validate the source data

From the repository root:

```bash
python3 scripts/generate_data.py
python3 scripts/validate_generated_data.py
```

The second command exits with an error if any row count, relationship, date range, or injected quality-case count differs from the manifest.

## 2. Run PostgreSQL

Ensure the PostgreSQL server is running. The pipeline defaults to host `127.0.0.1`, port `5432`, and the current operating-system username. Standard PostgreSQL environment variables can override those values.

```bash
bash scripts/run_pipeline.sh
```

The script creates `supply_chain_control_tower` when absent, then runs all numbered SQL files. It stops immediately on the first failed import, test, or SQL statement.

## 3. Verify the final evidence

```sql
SELECT * FROM audit.raw_load_summary;
SELECT * FROM audit.data_quality_results;
SELECT * FROM audit.cleaning_summary;
SELECT * FROM audit.model_quality_results;
SELECT * FROM analytics.vw_executive_kpis;
```

Expected final condition:

- every raw-load reconciliation is `PASS`;
- all 18 source-quality checks match the manifest;
- all ten dimensional-model checks have zero issues;
- the executive KPI view returns one row.

## 4. Rebuild the Power BI workbook

The SQL pipeline exports eight star-schema CSV files to the ignored `data/tmp/powerbi_source/` directory. The provided workbook builder combines them into the browser-ready Excel source described in `powerbi/mac_workflow.md`.

Inside Codex, where the bundled spreadsheet runtime is available:

```bash
node scripts/build_powerbi_workbook.mjs
node scripts/verify_powerbi_workbook.mjs
```

The finished workbook is committed under `outputs/`, so PostgreSQL and Python users do not need this private runtime simply to review or upload the model.

## 5. Expected model sizes

| Object | Expected rows |
|---|---:|
| `analytics.fact_orders` | 30,000 |
| `analytics.fact_shipments` | 28,534 |
| `analytics.fact_inventory` | 262,800 |
| `analytics.dim_date` | 372 including unknown |
| `analytics.dim_product` | 121 including unknown |
| `analytics.dim_customer` | 4,001 including unknown |
| `analytics.dim_warehouse` | 7 including unknown |
| `analytics.dim_carrier` | 8 including unknown |

These values are assertions for the fixed synthetic seed, not hard-coded substitutes for validation.
