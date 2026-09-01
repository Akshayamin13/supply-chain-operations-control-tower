\set ON_ERROR_STOP on

-- Run this script while connected to the default postgres database.
-- psql's \gexec executes CREATE DATABASE only when the project database is absent.
SELECT 'CREATE DATABASE supply_chain_control_tower'
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_database
    WHERE datname = 'supply_chain_control_tower'
) \gexec

\connect supply_chain_control_tower

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS clean;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS analytics.project_parameters (
    parameter_name text PRIMARY KEY,
    date_value date,
    text_value text,
    description text NOT NULL
);

INSERT INTO analytics.project_parameters (parameter_name, date_value, text_value, description)
VALUES
    ('analysis_date', DATE '2026-09-01', NULL, 'Fixed reporting date used for backlog ageing and open SLA calculations'),
    ('data_start_date', DATE '2025-09-01', NULL, 'First date included in the synthetic scenario'),
    ('data_end_date', DATE '2026-08-31', NULL, 'Last source-data date included in the synthetic scenario'),
    ('currency', NULL, 'EUR', 'Currency used for order value, product cost, price, and shipping cost')
ON CONFLICT (parameter_name) DO UPDATE
SET date_value = EXCLUDED.date_value,
    text_value = EXCLUDED.text_value,
    description = EXCLUDED.description;

CREATE TABLE IF NOT EXISTS audit.pipeline_runs (
    pipeline_run_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    started_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    completed_at timestamptz,
    pipeline_status text NOT NULL DEFAULT 'RUNNING',
    notes text
);

COMMENT ON SCHEMA raw IS 'Unmodified source-like text imported from generated CSV files.';
COMMENT ON SCHEMA clean IS 'Typed, deduplicated, standardised records with explicit quality flags.';
COMMENT ON SCHEMA analytics IS 'Reporting views, dimensional model, and business-facing outputs.';
COMMENT ON SCHEMA audit IS 'Load reconciliation, data-quality, cleaning, and model-test evidence.';
