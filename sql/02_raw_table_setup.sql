\set ON_ERROR_STOP on

DROP TABLE IF EXISTS raw.inventory;
DROP TABLE IF EXISTS raw.shipments;
DROP TABLE IF EXISTS raw.orders;
DROP TABLE IF EXISTS raw.customers;
DROP TABLE IF EXISTS raw.carriers;
DROP TABLE IF EXISTS raw.warehouses;
DROP TABLE IF EXISTS raw.products;

CREATE TABLE raw.products (
    source_row_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id text,
    product_name text,
    product_category text,
    unit_cost_eur text,
    unit_price_eur text,
    weight_kg text,
    supplier_lead_time_days text,
    source_file text NOT NULL DEFAULT 'products.csv',
    loaded_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE TABLE raw.warehouses (
    source_row_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_id text,
    warehouse_name text,
    city text,
    country text,
    storage_capacity_units text,
    daily_order_capacity text,
    source_file text NOT NULL DEFAULT 'warehouses.csv',
    loaded_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE raw.carriers (
    source_row_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    carrier_id text,
    carrier_name text,
    service_level text,
    base_transit_days text,
    source_file text NOT NULL DEFAULT 'carriers.csv',
    loaded_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE raw.customers (
    source_row_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id text,
    customer_name text,
    customer_segment text,
    city text,
    country text,
    signup_date text,
    source_file text NOT NULL DEFAULT 'customers.csv',
    loaded_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE raw.orders (
    source_row_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id text,
    customer_id text,
    product_id text,
    warehouse_id text,
    order_date text,
    promised_delivery_date text,
    order_status text,
    order_quantity text,
    unit_price_eur text,
    discount_pct text,
    order_value_eur text,
    sales_channel text,
    source_file text NOT NULL DEFAULT 'orders.csv',
    loaded_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE raw.shipments (
    source_row_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shipment_id text,
    order_id text,
    carrier_id text,
    ship_date text,
    actual_delivery_date text,
    shipment_status text,
    shipping_cost_eur text,
    exception_reason text,
    source_file text NOT NULL DEFAULT 'shipments.csv',
    loaded_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE raw.inventory (
    source_row_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inventory_date text,
    warehouse_id text,
    product_id text,
    opening_stock text,
    received_quantity text,
    shipped_quantity text,
    closing_stock text,
    reorder_level text,
    source_file text NOT NULL DEFAULT 'inventory.csv',
    loaded_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
