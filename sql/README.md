# SQL execution order

The SQL layer will be added gradually and run in numbered order:

1. `01_database_setup.sql`
2. `02_raw_table_setup.sql`
3. `03_data_import.sql`
4. `04_data_quality_checks.sql`
5. `05_data_cleaning.sql`
6. `06_kpi_queries.sql`
7. `07_operations_analysis.sql`
8. `08_star_schema.sql`
9. `09_model_quality_checks.sql`

The exact split may be refined as the model develops. SQL files have not been created yet because the source grain and data dictionary must be agreed first.
