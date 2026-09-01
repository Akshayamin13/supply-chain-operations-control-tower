\set ON_ERROR_STOP on

TRUNCATE TABLE
    raw.products,
    raw.warehouses,
    raw.carriers,
    raw.customers,
    raw.orders,
    raw.shipments,
    raw.inventory
RESTART IDENTITY;

-- Run psql from the repository root so these relative paths resolve correctly.
\copy raw.products (product_id, product_name, product_category, unit_cost_eur, unit_price_eur, weight_kg, supplier_lead_time_days) FROM 'data/raw/products.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy raw.warehouses (warehouse_id, warehouse_name, city, country, storage_capacity_units, daily_order_capacity) FROM 'data/raw/warehouses.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy raw.carriers (carrier_id, carrier_name, service_level, base_transit_days) FROM 'data/raw/carriers.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy raw.customers (customer_id, customer_name, customer_segment, city, country, signup_date) FROM 'data/raw/customers.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy raw.orders (order_id, customer_id, product_id, warehouse_id, order_date, promised_delivery_date, order_status, order_quantity, unit_price_eur, discount_pct, order_value_eur, sales_channel) FROM 'data/raw/orders.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy raw.shipments (shipment_id, order_id, carrier_id, ship_date, actual_delivery_date, shipment_status, shipping_cost_eur, exception_reason) FROM 'data/raw/shipments.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy raw.inventory (inventory_date, warehouse_id, product_id, opening_stock, received_quantity, shipped_quantity, closing_stock, reorder_level) FROM 'data/raw/inventory.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS audit.raw_load_summary;
CREATE TABLE audit.raw_load_summary (
    table_name text PRIMARY KEY,
    expected_row_count bigint NOT NULL,
    actual_row_count bigint NOT NULL,
    reconciliation_status text NOT NULL,
    checked_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

INSERT INTO audit.raw_load_summary (table_name, expected_row_count, actual_row_count, reconciliation_status)
SELECT table_name,
       expected_row_count,
       actual_row_count,
       CASE WHEN expected_row_count = actual_row_count THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT 'products' AS table_name, 120::bigint AS expected_row_count, COUNT(*)::bigint AS actual_row_count FROM raw.products
    UNION ALL SELECT 'warehouses', 6, COUNT(*) FROM raw.warehouses
    UNION ALL SELECT 'carriers', 7, COUNT(*) FROM raw.carriers
    UNION ALL SELECT 'customers', 4000, COUNT(*) FROM raw.customers
    UNION ALL SELECT 'orders', 30060, COUNT(*) FROM raw.orders
    UNION ALL SELECT 'shipments', 28584, COUNT(*) FROM raw.shipments
    UNION ALL SELECT 'inventory', 262880, COUNT(*) FROM raw.inventory
) AS reconciled;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM audit.raw_load_summary WHERE reconciliation_status = 'FAIL') THEN
        RAISE EXCEPTION 'Raw import reconciliation failed. Inspect audit.raw_load_summary.';
    END IF;
END $$;

TABLE audit.raw_load_summary;
