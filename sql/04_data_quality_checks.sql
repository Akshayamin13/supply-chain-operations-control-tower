\set ON_ERROR_STOP on

DROP TABLE IF EXISTS audit.data_quality_results;
CREATE TABLE audit.data_quality_results (
    check_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name text NOT NULL,
    check_name text NOT NULL,
    severity text NOT NULL,
    issue_count bigint NOT NULL,
    expected_issue_count bigint NOT NULL,
    check_status text NOT NULL,
    business_reason text NOT NULL,
    checked_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE (table_name, check_name)
);

WITH checks AS (
    SELECT 'products'::text AS table_name,
           'noncanonical_category'::text AS check_name,
           'WARNING'::text AS severity,
           COUNT(*)::bigint AS issue_count,
           12::bigint AS expected_issue_count,
           'Inconsistent category labels split one product group across several report values.'::text AS business_reason
    FROM raw.products
    WHERE product_category NOT IN ('Electronics', 'Home & Kitchen', 'Personal Care', 'Sports & Outdoors', 'Office Supplies', 'Accessories')

    UNION ALL
    SELECT 'orders', 'duplicate_order_id', 'CRITICAL',
           COALESCE(SUM(row_count - 1), 0)::bigint, 60,
           'Duplicate business keys overstate orders, revenue, and demand.'
    FROM (SELECT order_id, COUNT(*) AS row_count FROM raw.orders GROUP BY order_id HAVING COUNT(*) > 1) duplicates

    UNION ALL
    SELECT 'orders', 'missing_customer_id', 'WARNING', COUNT(*), 20,
           'Orders without customers cannot support segment or customer analysis.'
    FROM raw.orders WHERE NULLIF(BTRIM(customer_id), '') IS NULL

    UNION ALL
    SELECT 'orders', 'missing_product_id', 'CRITICAL', COUNT(*), 18,
           'Orders without products cannot be linked to cost, category, or inventory.'
    FROM raw.orders WHERE NULLIF(BTRIM(product_id), '') IS NULL

    UNION ALL
    SELECT 'orders', 'missing_warehouse_id', 'CRITICAL', COUNT(*), 24,
           'Orders without warehouses cannot support fulfilment-centre performance.'
    FROM raw.orders WHERE NULLIF(BTRIM(warehouse_id), '') IS NULL

    UNION ALL
    SELECT 'orders', 'unmapped_warehouse_id', 'CRITICAL', COUNT(*), 10,
           'Unknown warehouse codes break referential integrity.'
    FROM raw.orders o
    WHERE NULLIF(BTRIM(o.warehouse_id), '') IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM raw.warehouses w WHERE w.warehouse_id = o.warehouse_id)

    UNION ALL
    SELECT 'orders', 'nonpositive_quantity', 'CRITICAL', COUNT(*), 25,
           'Negative or zero demand corrupts units, revenue, and inventory calculations.'
    FROM raw.orders WHERE NULLIF(BTRIM(order_quantity), '')::integer <= 0

    UNION ALL
    SELECT 'orders', 'promised_before_order', 'CRITICAL', COUNT(*), 30,
           'A delivery promise cannot logically precede order placement.'
    FROM raw.orders
    WHERE promised_delivery_date::date < order_date::date

    UNION ALL
    SELECT 'orders', 'noncanonical_status', 'WARNING', COUNT(*), 45,
           'Inconsistent lifecycle statuses fragment backlog and fulfilment reporting.'
    FROM raw.orders
    WHERE order_status NOT IN ('Delivered', 'In Transit', 'Packed', 'Processing', 'On Hold', 'Cancelled')

    UNION ALL
    SELECT 'shipments', 'duplicate_shipment_id', 'CRITICAL',
           COALESCE(SUM(row_count - 1), 0)::bigint, 50,
           'Duplicate shipments overstate volume, cost, and exceptions.'
    FROM (SELECT shipment_id, COUNT(*) AS row_count FROM raw.shipments GROUP BY shipment_id HAVING COUNT(*) > 1) duplicates

    UNION ALL
    SELECT 'shipments', 'missing_carrier_id', 'WARNING', COUNT(*), 35,
           'Missing carriers prevent carrier-level accountability.'
    FROM raw.shipments WHERE NULLIF(BTRIM(carrier_id), '') IS NULL

    UNION ALL
    SELECT 'shipments', 'orphan_order_id', 'CRITICAL', COUNT(*), 12,
           'A shipment without a valid order cannot be reconciled to demand or revenue.'
    FROM raw.shipments s
    WHERE NOT EXISTS (SELECT 1 FROM raw.orders o WHERE o.order_id = s.order_id)

    UNION ALL
    SELECT 'shipments', 'delivery_before_ship', 'CRITICAL', COUNT(*), 35,
           'Delivery before dispatch is an impossible event sequence.'
    FROM raw.shipments
    WHERE NULLIF(BTRIM(actual_delivery_date), '') IS NOT NULL
      AND actual_delivery_date::date < ship_date::date

    UNION ALL
    SELECT 'shipments', 'noncanonical_status', 'WARNING', COUNT(*), 30,
           'Inconsistent shipment statuses split delivery reporting.'
    FROM raw.shipments WHERE shipment_status NOT IN ('Delivered', 'In Transit')

    UNION ALL
    SELECT 'inventory', 'duplicate_snapshot_key', 'CRITICAL',
           COALESCE(SUM(row_count - 1), 0)::bigint, 80,
           'Duplicate date-warehouse-product snapshots overstate inventory exposure.'
    FROM (
        SELECT inventory_date, warehouse_id, product_id, COUNT(*) AS row_count
        FROM raw.inventory
        GROUP BY inventory_date, warehouse_id, product_id
        HAVING COUNT(*) > 1
    ) duplicates

    UNION ALL
    SELECT 'inventory', 'missing_product_id', 'CRITICAL', COUNT(*), 15,
           'Inventory without a product cannot be valued or connected to demand.'
    FROM raw.inventory WHERE NULLIF(BTRIM(product_id), '') IS NULL

    UNION ALL
    SELECT 'inventory', 'negative_closing_stock', 'CRITICAL', COUNT(*), 20,
           'A physical closing balance below zero indicates a source or timing error.'
    FROM raw.inventory WHERE closing_stock::integer < 0

    UNION ALL
    SELECT 'inventory', 'balance_mismatch', 'CRITICAL', COUNT(*), 60,
           'Opening plus receipts minus shipments must reconcile to closing stock.'
    FROM raw.inventory
    WHERE opening_stock::integer + received_quantity::integer - shipped_quantity::integer <> closing_stock::integer
)
INSERT INTO audit.data_quality_results (
    table_name, check_name, severity, issue_count, expected_issue_count, check_status, business_reason
)
SELECT table_name,
       check_name,
       severity,
       issue_count,
       expected_issue_count,
       CASE WHEN issue_count = expected_issue_count THEN 'PASS' ELSE 'FAIL' END,
       business_reason
FROM checks;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM audit.data_quality_results WHERE check_status = 'FAIL') THEN
        RAISE EXCEPTION 'Data-quality counts differ from the manifest. Inspect audit.data_quality_results.';
    END IF;
END $$;

SELECT table_name, check_name, severity, issue_count, expected_issue_count, check_status
FROM audit.data_quality_results
ORDER BY table_name, check_id;
