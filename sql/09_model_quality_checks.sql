\set ON_ERROR_STOP on

DROP TABLE IF EXISTS audit.model_quality_results;
CREATE TABLE audit.model_quality_results (
    check_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    check_name text UNIQUE NOT NULL,
    issue_count bigint NOT NULL,
    expected_issue_count bigint NOT NULL DEFAULT 0,
    check_status text NOT NULL,
    business_reason text NOT NULL,
    checked_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

WITH checks AS (
    SELECT 'fact_orders_row_reconciliation'::text AS check_name,
           ABS((SELECT COUNT(*) FROM clean.orders) - (SELECT COUNT(*) FROM analytics.fact_orders))::bigint AS issue_count,
           'Every cleaned order must appear once in FactOrders.'::text AS business_reason
    UNION ALL
    SELECT 'fact_shipments_row_reconciliation',
           ABS((SELECT COUNT(*) FROM clean.shipments) - (SELECT COUNT(*) FROM analytics.fact_shipments))::bigint,
           'Every cleaned shipment must appear once in FactShipments.'
    UNION ALL
    SELECT 'fact_inventory_row_reconciliation',
           ABS((SELECT COUNT(*) FROM clean.inventory) - (SELECT COUNT(*) FROM analytics.fact_inventory))::bigint,
           'Every deduplicated inventory snapshot must appear once in FactInventory.'
    UNION ALL
    SELECT 'duplicate_fact_order_id',
           COALESCE(SUM(row_count - 1), 0)::bigint,
           'FactOrders must preserve one row per order.'
    FROM (SELECT order_id, COUNT(*) AS row_count FROM analytics.fact_orders GROUP BY order_id HAVING COUNT(*) > 1) duplicates
    UNION ALL
    SELECT 'duplicate_fact_shipment_id',
           COALESCE(SUM(row_count - 1), 0)::bigint,
           'FactShipments must preserve one row per shipment.'
    FROM (SELECT shipment_id, COUNT(*) AS row_count FROM analytics.fact_shipments GROUP BY shipment_id HAVING COUNT(*) > 1) duplicates
    UNION ALL
    SELECT 'eligible_orders_with_unknown_dimension', COUNT(*),
           'Analysis-eligible orders must resolve every customer, product, and warehouse key.'
    FROM analytics.fact_orders
    WHERE is_analysis_eligible AND (customer_key = 0 OR product_key = 0 OR warehouse_key = 0 OR order_date_key = 0 OR promised_delivery_date_key = 0)
    UNION ALL
    SELECT 'eligible_shipments_with_unknown_operational_dimension', COUNT(*),
           'Analysis-eligible shipments must resolve order-derived product, warehouse, customer, and dates; missing carrier is retained as Unknown by design.'
    FROM analytics.fact_shipments
    WHERE is_analysis_eligible AND (customer_key = 0 OR product_key = 0 OR warehouse_key = 0 OR ship_date_key = 0)
    UNION ALL
    SELECT 'eligible_inventory_with_unknown_dimension', COUNT(*),
           'Analysis-eligible inventory must resolve date, product, and warehouse keys.'
    FROM analytics.fact_inventory
    WHERE is_analysis_eligible AND (inventory_date_key = 0 OR product_key = 0 OR warehouse_key = 0)
    UNION ALL
    SELECT 'eligible_order_revenue_reconciliation',
           CASE WHEN ABS(
               (SELECT SUM(order_value_eur) FROM clean.orders WHERE is_analysis_eligible)
               - (SELECT SUM(order_value_eur) FROM analytics.fact_orders WHERE is_analysis_eligible)
           ) < 0.01 THEN 0 ELSE 1 END,
           'Eligible order value must reconcile exactly between clean and star-schema layers.'
    UNION ALL
    SELECT 'date_dimension_coverage',
           CASE WHEN (SELECT COUNT(*) FROM analytics.dim_date WHERE date_key <> 0) = 371 THEN 0 ELSE 1 END,
           'DimDate must cover every day from 2025-09-01 through the latest promised delivery date, 2026-09-06.'
)
INSERT INTO audit.model_quality_results (
    check_name, issue_count, expected_issue_count, check_status, business_reason
)
SELECT check_name,
       issue_count,
       0,
       CASE WHEN issue_count = 0 THEN 'PASS' ELSE 'FAIL' END,
       business_reason
FROM checks;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM audit.model_quality_results WHERE check_status = 'FAIL') THEN
        RAISE EXCEPTION 'Star-schema validation failed. Inspect audit.model_quality_results.';
    END IF;
END $$;

SELECT check_name, issue_count, check_status
FROM audit.model_quality_results
ORDER BY check_id;
