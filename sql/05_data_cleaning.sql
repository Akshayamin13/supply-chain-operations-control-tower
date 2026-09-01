\set ON_ERROR_STOP on

DROP SCHEMA IF EXISTS clean CASCADE;
CREATE SCHEMA clean;

CREATE TABLE clean.products (
    product_id text PRIMARY KEY,
    product_name text NOT NULL,
    product_category text NOT NULL,
    unit_cost_eur numeric(10, 2) NOT NULL CHECK (unit_cost_eur > 0),
    unit_price_eur numeric(10, 2) NOT NULL CHECK (unit_price_eur > 0),
    weight_kg numeric(8, 2) NOT NULL CHECK (weight_kg > 0),
    supplier_lead_time_days integer NOT NULL CHECK (supplier_lead_time_days > 0)
);

INSERT INTO clean.products
SELECT DISTINCT ON (product_id)
       BTRIM(product_id),
       BTRIM(product_name),
       CASE LOWER(REPLACE(BTRIM(product_category), ' and ', ' & '))
           WHEN 'electronics' THEN 'Electronics'
           WHEN 'home & kitchen' THEN 'Home & Kitchen'
           WHEN 'personal care' THEN 'Personal Care'
           WHEN 'sports & outdoors' THEN 'Sports & Outdoors'
           WHEN 'office supplies' THEN 'Office Supplies'
           WHEN 'accessories' THEN 'Accessories'
           ELSE 'Unknown'
       END,
       unit_cost_eur::numeric(10, 2),
       unit_price_eur::numeric(10, 2),
       weight_kg::numeric(8, 2),
       supplier_lead_time_days::integer
FROM raw.products
WHERE NULLIF(BTRIM(product_id), '') IS NOT NULL
ORDER BY product_id, source_row_id;

CREATE TABLE clean.warehouses (
    warehouse_id text PRIMARY KEY,
    warehouse_name text NOT NULL,
    city text NOT NULL,
    country text NOT NULL,
    storage_capacity_units integer NOT NULL CHECK (storage_capacity_units > 0),
    daily_order_capacity integer NOT NULL CHECK (daily_order_capacity > 0)
);

INSERT INTO clean.warehouses
SELECT DISTINCT ON (warehouse_id)
       BTRIM(warehouse_id), BTRIM(warehouse_name), BTRIM(city), UPPER(BTRIM(country)),
       storage_capacity_units::integer, daily_order_capacity::integer
FROM raw.warehouses
WHERE NULLIF(BTRIM(warehouse_id), '') IS NOT NULL
ORDER BY warehouse_id, source_row_id;

CREATE TABLE clean.carriers (
    carrier_id text PRIMARY KEY,
    carrier_name text NOT NULL,
    service_level text NOT NULL,
    base_transit_days integer NOT NULL CHECK (base_transit_days > 0)
);

INSERT INTO clean.carriers
SELECT DISTINCT ON (carrier_id)
       BTRIM(carrier_id), BTRIM(carrier_name), INITCAP(BTRIM(service_level)), base_transit_days::integer
FROM raw.carriers
WHERE NULLIF(BTRIM(carrier_id), '') IS NOT NULL
ORDER BY carrier_id, source_row_id;

CREATE TABLE clean.customers (
    customer_id text PRIMARY KEY,
    customer_name text NOT NULL,
    customer_segment text NOT NULL,
    city text NOT NULL,
    country text NOT NULL,
    signup_date date NOT NULL
);

INSERT INTO clean.customers
SELECT DISTINCT ON (customer_id)
       BTRIM(customer_id), BTRIM(customer_name), BTRIM(customer_segment), BTRIM(city),
       UPPER(BTRIM(country)), signup_date::date
FROM raw.customers
WHERE NULLIF(BTRIM(customer_id), '') IS NOT NULL
ORDER BY customer_id, source_row_id;

CREATE TABLE clean.orders (
    order_id text PRIMARY KEY,
    customer_id text,
    product_id text,
    warehouse_id text,
    order_date date NOT NULL,
    promised_delivery_date date,
    order_status text NOT NULL,
    order_quantity integer,
    unit_price_eur numeric(10, 2) NOT NULL,
    discount_pct numeric(6, 4) NOT NULL,
    order_value_eur numeric(12, 2) NOT NULL,
    sales_channel text NOT NULL,
    has_customer_mapping boolean NOT NULL,
    has_product_mapping boolean NOT NULL,
    has_warehouse_mapping boolean NOT NULL,
    has_valid_quantity boolean NOT NULL,
    has_valid_dates boolean NOT NULL,
    is_analysis_eligible boolean NOT NULL,
    data_quality_note text
);

WITH ranked AS (
    SELECT o.*,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY source_row_id) AS duplicate_rank
    FROM raw.orders o
), typed AS (
    SELECT BTRIM(order_id) AS order_id,
           NULLIF(BTRIM(customer_id), '') AS customer_id,
           NULLIF(BTRIM(product_id), '') AS product_id,
           NULLIF(BTRIM(warehouse_id), '') AS warehouse_id,
           order_date::date AS order_date,
           promised_delivery_date::date AS raw_promised_delivery_date,
           CASE LOWER(BTRIM(order_status))
               WHEN 'delivered' THEN 'Delivered'
               WHEN 'in transit' THEN 'In Transit'
               WHEN 'dispatchd' THEN 'In Transit'
               WHEN 'processing' THEN 'Processing'
               WHEN 'packed' THEN 'Packed'
               WHEN 'on hold' THEN 'On Hold'
               WHEN 'on-hold' THEN 'On Hold'
               WHEN 'cancelled' THEN 'Cancelled'
               WHEN 'cancel' THEN 'Cancelled'
               ELSE 'Unknown'
           END AS order_status,
           order_quantity::integer AS raw_order_quantity,
           unit_price_eur::numeric(10, 2) AS unit_price_eur,
           discount_pct::numeric(6, 4) AS discount_pct,
           order_value_eur::numeric(12, 2) AS order_value_eur,
           BTRIM(sales_channel) AS sales_channel
    FROM ranked
    WHERE duplicate_rank = 1
), assessed AS (
    SELECT t.*,
           EXISTS (SELECT 1 FROM clean.customers c WHERE c.customer_id = t.customer_id) AS has_customer_mapping,
           EXISTS (SELECT 1 FROM clean.products p WHERE p.product_id = t.product_id) AS has_product_mapping,
           EXISTS (SELECT 1 FROM clean.warehouses w WHERE w.warehouse_id = t.warehouse_id) AS has_warehouse_mapping,
           t.raw_order_quantity > 0 AS has_valid_quantity,
           t.raw_promised_delivery_date >= t.order_date AS has_valid_dates
    FROM typed t
)
INSERT INTO clean.orders
SELECT order_id,
       customer_id,
       product_id,
       warehouse_id,
       order_date,
       CASE WHEN has_valid_dates THEN raw_promised_delivery_date END,
       order_status,
       CASE WHEN has_valid_quantity THEN raw_order_quantity END,
       unit_price_eur,
       discount_pct,
       order_value_eur,
       sales_channel,
       has_customer_mapping,
       has_product_mapping,
       has_warehouse_mapping,
       has_valid_quantity,
       has_valid_dates,
       has_customer_mapping AND has_product_mapping AND has_warehouse_mapping
           AND has_valid_quantity AND has_valid_dates AND order_status <> 'Unknown',
       NULLIF(CONCAT_WS('; ',
           CASE WHEN NOT has_customer_mapping THEN 'missing or unmapped customer' END,
           CASE WHEN NOT has_product_mapping THEN 'missing or unmapped product' END,
           CASE WHEN NOT has_warehouse_mapping THEN 'missing or unmapped warehouse' END,
           CASE WHEN NOT has_valid_quantity THEN 'invalid quantity' END,
           CASE WHEN NOT has_valid_dates THEN 'promised date before order date' END,
           CASE WHEN order_status = 'Unknown' THEN 'unknown order status' END
       ), '')
FROM assessed;

CREATE INDEX orders_customer_idx ON clean.orders (customer_id);
CREATE INDEX orders_product_idx ON clean.orders (product_id);
CREATE INDEX orders_warehouse_idx ON clean.orders (warehouse_id);
CREATE INDEX orders_order_date_idx ON clean.orders (order_date);
CREATE INDEX orders_status_idx ON clean.orders (order_status);

CREATE TABLE clean.shipments (
    shipment_id text PRIMARY KEY,
    order_id text,
    carrier_id text,
    ship_date date NOT NULL,
    actual_delivery_date date,
    shipment_status text NOT NULL,
    shipping_cost_eur numeric(10, 2) NOT NULL,
    exception_reason text,
    has_order_mapping boolean NOT NULL,
    has_carrier_mapping boolean NOT NULL,
    has_valid_dates boolean NOT NULL,
    is_analysis_eligible boolean NOT NULL,
    data_quality_note text
);

WITH ranked AS (
    SELECT s.*,
           ROW_NUMBER() OVER (PARTITION BY shipment_id ORDER BY source_row_id) AS duplicate_rank
    FROM raw.shipments s
), typed AS (
    SELECT BTRIM(shipment_id) AS shipment_id,
           NULLIF(BTRIM(order_id), '') AS order_id,
           NULLIF(BTRIM(carrier_id), '') AS carrier_id,
           ship_date::date AS ship_date,
           NULLIF(BTRIM(actual_delivery_date), '')::date AS raw_actual_delivery_date,
           CASE REPLACE(LOWER(BTRIM(shipment_status)), '-', ' ')
               WHEN 'delivered' THEN 'Delivered'
               WHEN 'in transit' THEN 'In Transit'
               ELSE 'Unknown'
           END AS shipment_status,
           shipping_cost_eur::numeric(10, 2) AS shipping_cost_eur,
           NULLIF(BTRIM(exception_reason), '') AS exception_reason
    FROM ranked
    WHERE duplicate_rank = 1
), assessed AS (
    SELECT t.*,
           EXISTS (SELECT 1 FROM clean.orders o WHERE o.order_id = t.order_id) AS has_order_mapping,
           EXISTS (SELECT 1 FROM clean.carriers c WHERE c.carrier_id = t.carrier_id) AS has_carrier_mapping,
           t.raw_actual_delivery_date IS NULL OR t.raw_actual_delivery_date >= t.ship_date AS has_valid_dates
    FROM typed t
)
INSERT INTO clean.shipments
SELECT shipment_id,
       order_id,
       carrier_id,
       ship_date,
       CASE WHEN has_valid_dates THEN raw_actual_delivery_date END,
       shipment_status,
       shipping_cost_eur,
       exception_reason,
       has_order_mapping,
       has_carrier_mapping,
       has_valid_dates,
       has_order_mapping AND has_valid_dates AND shipment_status <> 'Unknown',
       NULLIF(CONCAT_WS('; ',
           CASE WHEN NOT has_order_mapping THEN 'orphan order reference' END,
           CASE WHEN NOT has_carrier_mapping THEN 'missing or unmapped carrier' END,
           CASE WHEN NOT has_valid_dates THEN 'delivery date before ship date' END,
           CASE WHEN shipment_status = 'Unknown' THEN 'unknown shipment status' END
       ), '')
FROM assessed;

CREATE INDEX shipments_order_idx ON clean.shipments (order_id);
CREATE INDEX shipments_carrier_idx ON clean.shipments (carrier_id);
CREATE INDEX shipments_ship_date_idx ON clean.shipments (ship_date);

CREATE TABLE clean.inventory (
    inventory_record_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inventory_date date NOT NULL,
    warehouse_id text,
    product_id text,
    opening_stock integer NOT NULL,
    received_quantity integer NOT NULL,
    shipped_quantity integer NOT NULL,
    closing_stock integer,
    reorder_level integer NOT NULL,
    has_product_mapping boolean NOT NULL,
    has_warehouse_mapping boolean NOT NULL,
    has_valid_balance boolean NOT NULL,
    is_analysis_eligible boolean NOT NULL,
    data_quality_note text
);

WITH ranked AS (
    SELECT i.*,
           ROW_NUMBER() OVER (
               PARTITION BY inventory_date, warehouse_id, product_id
               ORDER BY source_row_id
           ) AS duplicate_rank
    FROM raw.inventory i
), typed AS (
    SELECT inventory_date::date AS inventory_date,
           NULLIF(BTRIM(warehouse_id), '') AS warehouse_id,
           NULLIF(BTRIM(product_id), '') AS product_id,
           opening_stock::integer AS opening_stock,
           received_quantity::integer AS received_quantity,
           shipped_quantity::integer AS shipped_quantity,
           closing_stock::integer AS raw_closing_stock,
           reorder_level::integer AS reorder_level
    FROM ranked
    WHERE duplicate_rank = 1
), assessed AS (
    SELECT t.*,
           EXISTS (SELECT 1 FROM clean.products p WHERE p.product_id = t.product_id) AS has_product_mapping,
           EXISTS (SELECT 1 FROM clean.warehouses w WHERE w.warehouse_id = t.warehouse_id) AS has_warehouse_mapping,
           t.raw_closing_stock >= 0
               AND t.opening_stock + t.received_quantity - t.shipped_quantity = t.raw_closing_stock AS has_valid_balance
    FROM typed t
)
INSERT INTO clean.inventory (
    inventory_date, warehouse_id, product_id, opening_stock, received_quantity,
    shipped_quantity, closing_stock, reorder_level, has_product_mapping,
    has_warehouse_mapping, has_valid_balance, is_analysis_eligible, data_quality_note
)
SELECT inventory_date,
       warehouse_id,
       product_id,
       opening_stock,
       received_quantity,
       shipped_quantity,
       CASE WHEN has_valid_balance THEN raw_closing_stock END,
       reorder_level,
       has_product_mapping,
       has_warehouse_mapping,
       has_valid_balance,
       has_product_mapping AND has_warehouse_mapping AND has_valid_balance,
       NULLIF(CONCAT_WS('; ',
           CASE WHEN NOT has_product_mapping THEN 'missing or unmapped product' END,
           CASE WHEN NOT has_warehouse_mapping THEN 'missing or unmapped warehouse' END,
           CASE WHEN NOT has_valid_balance THEN 'negative or unreconciled closing balance' END
       ), '')
FROM assessed;

CREATE INDEX inventory_date_idx ON clean.inventory (inventory_date);
CREATE INDEX inventory_product_idx ON clean.inventory (product_id);
CREATE INDEX inventory_warehouse_idx ON clean.inventory (warehouse_id);
CREATE UNIQUE INDEX inventory_valid_business_key_idx
    ON clean.inventory (inventory_date, warehouse_id, product_id)
    WHERE product_id IS NOT NULL AND warehouse_id IS NOT NULL;

DROP TABLE IF EXISTS audit.cleaning_summary;
CREATE TABLE audit.cleaning_summary (
    table_name text PRIMARY KEY,
    raw_row_count bigint NOT NULL,
    clean_row_count bigint NOT NULL,
    duplicate_rows_removed bigint NOT NULL,
    analysis_eligible_rows bigint NOT NULL,
    flagged_rows bigint NOT NULL,
    checked_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

INSERT INTO audit.cleaning_summary
SELECT 'orders',
       (SELECT COUNT(*) FROM raw.orders),
       COUNT(*),
       (SELECT COUNT(*) FROM raw.orders) - COUNT(*),
       COUNT(*) FILTER (WHERE is_analysis_eligible),
       COUNT(*) FILTER (WHERE NOT is_analysis_eligible),
       clock_timestamp()
FROM clean.orders
UNION ALL
SELECT 'shipments',
       (SELECT COUNT(*) FROM raw.shipments),
       COUNT(*),
       (SELECT COUNT(*) FROM raw.shipments) - COUNT(*),
       COUNT(*) FILTER (WHERE is_analysis_eligible),
       COUNT(*) FILTER (WHERE NOT is_analysis_eligible),
       clock_timestamp()
FROM clean.shipments
UNION ALL
SELECT 'inventory',
       (SELECT COUNT(*) FROM raw.inventory),
       COUNT(*),
       (SELECT COUNT(*) FROM raw.inventory) - COUNT(*),
       COUNT(*) FILTER (WHERE is_analysis_eligible),
       COUNT(*) FILTER (WHERE NOT is_analysis_eligible),
       clock_timestamp()
FROM clean.inventory;

ANALYZE clean.products;
ANALYZE clean.warehouses;
ANALYZE clean.carriers;
ANALYZE clean.customers;
ANALYZE clean.orders;
ANALYZE clean.shipments;
ANALYZE clean.inventory;

TABLE audit.cleaning_summary;

