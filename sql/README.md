# SQL execution order

Run the complete layer with `bash scripts/run_pipeline.sh`, or execute these files in order:

1. `01_database_setup.sql`
2. `02_raw_table_setup.sql`
3. `03_data_import.sql`
4. `04_data_quality_checks.sql`
5. `05_data_cleaning.sql`
6. `06_kpi_queries.sql`
7. `07_operations_analysis.sql`
8. `08_star_schema.sql`
9. `09_model_quality_checks.sql`
10. `10_export_results.sql`
11. `11_export_powerbi_tables.sql`
12. `12_sql_learning_queries.sql`

The pipeline stops on the first failed import, quality assertion, model test, or SQL error. See the [pipeline and cleaning notes](../documentation/pipeline.md) for the purpose and decisions in each stage.
