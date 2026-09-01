#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POSTGRES_HOST="${PGHOST:-127.0.0.1}"
POSTGRES_PORT="${PGPORT:-5432}"
POSTGRES_USER="${PGUSER:-${USER}}"
PROJECT_DATABASE="supply_chain_control_tower"

cd "${PROJECT_ROOT}"
mkdir -p "${PROJECT_ROOT}/data/tmp/powerbi_source"

psql -X -v ON_ERROR_STOP=1 -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d postgres -f sql/01_database_setup.sql

for sql_file in \
    sql/02_raw_table_setup.sql \
    sql/03_data_import.sql \
    sql/04_data_quality_checks.sql \
    sql/05_data_cleaning.sql \
    sql/06_kpi_queries.sql \
    sql/07_operations_analysis.sql \
    sql/08_star_schema.sql \
    sql/09_model_quality_checks.sql \
    sql/10_export_results.sql \
    sql/11_export_powerbi_tables.sql \
    sql/12_sql_learning_queries.sql
do
    psql -X -v ON_ERROR_STOP=1 -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${PROJECT_DATABASE}" -f "${sql_file}"
done

echo "Pipeline completed successfully."
