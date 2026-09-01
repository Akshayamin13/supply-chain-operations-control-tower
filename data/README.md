# Data directory

## `raw/`

Source-like synthetic CSV files are generated reproducibly and preserved unchanged. Cleaning happens in SQL, not by manually editing these files.

The folder contains seven source tables covering 2025-09-01 through 2026-08-31. `SHA256SUMS.txt` allows the files to be checked for accidental changes.

## `processed/`

Eleven controlled exports produced by `sql/10_export_results.sql`. They contain the executive KPI row and the evidence tables used for warehouse, carrier, exception, backlog, stockout, capacity, segment, product-risk, and high-risk-order analysis.

## `tmp/`

Disposable working files belong here and are ignored by Git.

## Quality controls

- `quality_manifest.json` records the deliberately injected defect counts.
- `data_profile.json` contains the independent validation result.
- The generator uses a fixed seed so reruns produce the same source files.
- PostgreSQL independently reconciles imported rows and all expected defect counts before cleaning begins.
