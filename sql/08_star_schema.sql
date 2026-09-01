\set ON_ERROR_STOP on

DROP VIEW IF EXISTS analytics.vw_powerbi_executive_kpis;
DROP VIEW IF EXISTS analytics.vw_powerbi_order_summary;
DROP VIEW IF EXISTS analytics.vw_powerbi_shipment_summary;
DROP VIEW IF EXISTS analytics.vw_powerbi_inventory_summary;
DROP VIEW IF EXISTS analytics.vw_powerbi_inventory_monthly;

DROP TABLE IF EXISTS analytics.fact_inventory;
DROP TABLE IF EXISTS analytics.fact_shipments;
DROP TABLE IF EXISTS analytics.fact_orders;
DROP TABLE IF EXISTS analytics.dim_carrier;
DROP TABLE IF EXISTS analytics.dim_warehouse;
DROP TABLE IF EXISTS analytics.dim_customer;
DROP TABLE IF EXISTS analytics.dim_product;
DROP TABLE IF EXISTS analytics.dim_date;

CREATE TABLE analytics.dim_date (
    date_key integer PRIMARY KEY,
    full_date date UNIQUE,
    day_of_month smallint,
    day_name text,
    iso_week smallint,
    month_number smallint,
    month_name text,
    month_start_date date,
    quarter_number smallint,
    year_number smallint,
    year_month text,
    is_weekend boolean
);

INSERT INTO analytics.dim_date
VALUES (0, NULL, NULL, 'Unknown', NULL, NULL, 'Unknown', NULL, NULL, NULL, 'Unknown', NULL);

INSERT INTO analytics.dim_date
SELECT TO_CHAR(calendar_date, 'YYYYMMDD')::integer,
       calendar_date,
       EXTRACT(DAY FROM calendar_date)::smallint,
       TO_CHAR(calendar_date, 'FMDay'),
       EXTRACT(WEEK FROM calendar_date)::smallint,
       EXTRACT(MONTH FROM calendar_date)::smallint,
       TO_CHAR(calendar_date, 'FMMonth'),
       DATE_TRUNC('month', calendar_date)::date,
       EXTRACT(QUARTER FROM calendar_date)::smallint,
       EXTRACT(YEAR FROM calendar_date)::smallint,
       TO_CHAR(calendar_date, 'YYYY-MM'),
       EXTRACT(ISODOW FROM calendar_date) IN (6, 7)
FROM GENERATE_SERIES(DATE '2025-09-01', DATE '2026-09-06', INTERVAL '1 day') AS dates(calendar_date);

CREATE TABLE analytics.dim_product (
    product_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id text UNIQUE NOT NULL,
    product_name text NOT NULL,
    product_category text NOT NULL,
    unit_cost_eur numeric(10, 2),
    unit_price_eur numeric(10, 2),
    weight_kg numeric(8, 2),
    supplier_lead_time_days integer
);

INSERT INTO analytics.dim_product (product_key, product_id, product_name, product_category)
OVERRIDING SYSTEM VALUE
VALUES (0, 'UNKNOWN', 'Unknown Product', 'Unknown');

INSERT INTO analytics.dim_product (
    product_id, product_name, product_category, unit_cost_eur, unit_price_eur, weight_kg, supplier_lead_time_days
)
SELECT product_id, product_name, product_category, unit_cost_eur, unit_price_eur, weight_kg, supplier_lead_time_days
FROM clean.products
ORDER BY product_id;

CREATE TABLE analytics.dim_customer (
    customer_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id text UNIQUE NOT NULL,
    customer_name text NOT NULL,
    customer_segment text NOT NULL,
    city text,
    country text,
    signup_date date
);

INSERT INTO analytics.dim_customer (customer_key, customer_id, customer_name, customer_segment)
OVERRIDING SYSTEM VALUE
VALUES (0, 'UNKNOWN', 'Unknown Customer', 'Unknown');

INSERT INTO analytics.dim_customer (customer_id, customer_name, customer_segment, city, country, signup_date)
SELECT customer_id, customer_name, customer_segment, city, country, signup_date
FROM clean.customers
ORDER BY customer_id;

CREATE TABLE analytics.dim_warehouse (
    warehouse_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_id text UNIQUE NOT NULL,
    warehouse_name text NOT NULL,
    city text,
    country text,
    storage_capacity_units integer,
    daily_order_capacity integer
);

INSERT INTO analytics.dim_warehouse (warehouse_key, warehouse_id, warehouse_name)
OVERRIDING SYSTEM VALUE
VALUES (0, 'UNKNOWN', 'Unknown Warehouse');

INSERT INTO analytics.dim_warehouse (
    warehouse_id, warehouse_name, city, country, storage_capacity_units, daily_order_capacity
)
SELECT warehouse_id, warehouse_name, city, country, storage_capacity_units, daily_order_capacity
FROM clean.warehouses
ORDER BY warehouse_id;

CREATE TABLE analytics.dim_carrier (
    carrier_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    carrier_id text UNIQUE NOT NULL,
    carrier_name text NOT NULL,
    service_level text,
    base_transit_days integer
);

INSERT INTO analytics.dim_carrier (carrier_key, carrier_id, carrier_name)
OVERRIDING SYSTEM VALUE
VALUES (0, 'UNKNOWN', 'Unknown Carrier');

INSERT INTO analytics.dim_carrier (carrier_id, carrier_name, service_level, base_transit_days)
SELECT carrier_id, carrier_name, service_level, base_transit_days
FROM clean.carriers
ORDER BY carrier_id;

CREATE TABLE analytics.fact_orders (
    order_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id text UNIQUE NOT NULL,
    order_date_key integer NOT NULL REFERENCES analytics.dim_date(date_key),
    promised_delivery_date_key integer NOT NULL REFERENCES analytics.dim_date(date_key),
    customer_key integer NOT NULL REFERENCES analytics.dim_customer(customer_key),
    product_key integer NOT NULL REFERENCES analytics.dim_product(product_key),
    warehouse_key integer NOT NULL REFERENCES analytics.dim_warehouse(warehouse_key),
    order_status text NOT NULL,
    sales_channel text NOT NULL,
    order_quantity integer,
    unit_price_eur numeric(10, 2) NOT NULL,
    discount_pct numeric(6, 4) NOT NULL,
    order_value_eur numeric(12, 2) NOT NULL,
    has_shipment boolean NOT NULL,
    is_backlog boolean NOT NULL,
    backlog_age_days integer,
    is_sla_breach boolean NOT NULL,
    fulfilment_is_analysis_eligible boolean NOT NULL,
    is_analysis_eligible boolean NOT NULL,
    data_quality_note text
);

INSERT INTO analytics.fact_orders (
    order_id, order_date_key, promised_delivery_date_key, customer_key, product_key,
    warehouse_key, order_status, sales_channel, order_quantity, unit_price_eur,
    discount_pct, order_value_eur, has_shipment, is_backlog, backlog_age_days,
    is_sla_breach, fulfilment_is_analysis_eligible, is_analysis_eligible, data_quality_note
)
SELECT o.order_id,
       COALESCE(od.date_key, 0),
       COALESCE(pd.date_key, 0),
       COALESCE(c.customer_key, 0),
       COALESCE(p.product_key, 0),
       COALESCE(w.warehouse_key, 0),
       o.order_status,
       o.sales_channel,
       o.order_quantity,
       o.unit_price_eur,
       o.discount_pct,
       o.order_value_eur,
       f.shipment_id IS NOT NULL,
       f.is_backlog,
       f.backlog_age_days,
       f.is_sla_breach,
       f.fulfilment_is_analysis_eligible,
       o.is_analysis_eligible,
       o.data_quality_note
FROM clean.orders o
JOIN analytics.vw_order_fulfilment f ON f.order_id = o.order_id
LEFT JOIN analytics.dim_date od ON od.full_date = o.order_date
LEFT JOIN analytics.dim_date pd ON pd.full_date = o.promised_delivery_date
LEFT JOIN analytics.dim_customer c ON c.customer_id = o.customer_id
LEFT JOIN analytics.dim_product p ON p.product_id = o.product_id
LEFT JOIN analytics.dim_warehouse w ON w.warehouse_id = o.warehouse_id;

CREATE TABLE analytics.fact_shipments (
    shipment_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shipment_id text UNIQUE NOT NULL,
    order_id text,
    ship_date_key integer NOT NULL REFERENCES analytics.dim_date(date_key),
    promised_delivery_date_key integer NOT NULL REFERENCES analytics.dim_date(date_key),
    actual_delivery_date_key integer NOT NULL REFERENCES analytics.dim_date(date_key),
    customer_key integer NOT NULL REFERENCES analytics.dim_customer(customer_key),
    product_key integer NOT NULL REFERENCES analytics.dim_product(product_key),
    warehouse_key integer NOT NULL REFERENCES analytics.dim_warehouse(warehouse_key),
    carrier_key integer NOT NULL REFERENCES analytics.dim_carrier(carrier_key),
    shipment_status text NOT NULL,
    shipping_cost_eur numeric(10, 2) NOT NULL,
    exception_reason text,
    delivery_delay_days integer,
    fulfilment_lead_time_days integer,
    is_on_time boolean,
    is_analysis_eligible boolean NOT NULL,
    data_quality_note text
);

INSERT INTO analytics.fact_shipments (
    shipment_id, order_id, ship_date_key, promised_delivery_date_key, actual_delivery_date_key,
    customer_key, product_key, warehouse_key, carrier_key, shipment_status,
    shipping_cost_eur, exception_reason, delivery_delay_days, fulfilment_lead_time_days,
    is_on_time, is_analysis_eligible, data_quality_note
)
SELECT s.shipment_id,
       s.order_id,
       COALESCE(sd.date_key, 0),
       COALESCE(pd.date_key, 0),
       COALESCE(ad.date_key, 0),
       COALESCE(c.customer_key, 0),
       COALESCE(p.product_key, 0),
       COALESCE(w.warehouse_key, 0),
       COALESCE(ca.carrier_key, 0),
       s.shipment_status,
       s.shipping_cost_eur,
       s.exception_reason,
       CASE WHEN s.actual_delivery_date IS NOT NULL AND o.promised_delivery_date IS NOT NULL
            THEN s.actual_delivery_date - o.promised_delivery_date END,
       CASE WHEN o.order_date IS NOT NULL THEN s.ship_date - o.order_date END,
       CASE WHEN s.actual_delivery_date IS NOT NULL AND o.promised_delivery_date IS NOT NULL
            THEN s.actual_delivery_date <= o.promised_delivery_date END,
       s.is_analysis_eligible AND COALESCE(o.is_analysis_eligible, false),
       NULLIF(CONCAT_WS('; ', s.data_quality_note, o.data_quality_note), '')
FROM clean.shipments s
LEFT JOIN clean.orders o ON o.order_id = s.order_id
LEFT JOIN analytics.dim_date sd ON sd.full_date = s.ship_date
LEFT JOIN analytics.dim_date pd ON pd.full_date = o.promised_delivery_date
LEFT JOIN analytics.dim_date ad ON ad.full_date = s.actual_delivery_date
LEFT JOIN analytics.dim_customer c ON c.customer_id = o.customer_id
LEFT JOIN analytics.dim_product p ON p.product_id = o.product_id
LEFT JOIN analytics.dim_warehouse w ON w.warehouse_id = o.warehouse_id
LEFT JOIN analytics.dim_carrier ca ON ca.carrier_id = s.carrier_id;

CREATE TABLE analytics.fact_inventory (
    inventory_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inventory_date_key integer NOT NULL REFERENCES analytics.dim_date(date_key),
    product_key integer NOT NULL REFERENCES analytics.dim_product(product_key),
    warehouse_key integer NOT NULL REFERENCES analytics.dim_warehouse(warehouse_key),
    opening_stock integer NOT NULL,
    received_quantity integer NOT NULL,
    shipped_quantity integer NOT NULL,
    closing_stock integer,
    reorder_level integer NOT NULL,
    is_stockout boolean,
    is_below_reorder boolean,
    is_analysis_eligible boolean NOT NULL,
    data_quality_note text
);

INSERT INTO analytics.fact_inventory (
    inventory_date_key, product_key, warehouse_key, opening_stock, received_quantity,
    shipped_quantity, closing_stock, reorder_level, is_stockout, is_below_reorder,
    is_analysis_eligible, data_quality_note
)
SELECT COALESCE(d.date_key, 0),
       COALESCE(p.product_key, 0),
       COALESCE(w.warehouse_key, 0),
       i.opening_stock,
       i.received_quantity,
       i.shipped_quantity,
       i.closing_stock,
       i.reorder_level,
       CASE WHEN i.closing_stock IS NOT NULL THEN i.closing_stock = 0 END,
       CASE WHEN i.closing_stock IS NOT NULL THEN i.closing_stock <= i.reorder_level END,
       i.is_analysis_eligible,
       i.data_quality_note
FROM clean.inventory i
LEFT JOIN analytics.dim_date d ON d.full_date = i.inventory_date
LEFT JOIN analytics.dim_product p ON p.product_id = i.product_id
LEFT JOIN analytics.dim_warehouse w ON w.warehouse_id = i.warehouse_id;

CREATE INDEX fact_orders_date_idx ON analytics.fact_orders (order_date_key);
CREATE INDEX fact_orders_product_idx ON analytics.fact_orders (product_key);
CREATE INDEX fact_orders_warehouse_idx ON analytics.fact_orders (warehouse_key);
CREATE INDEX fact_shipments_order_idx ON analytics.fact_shipments (order_id);
CREATE INDEX fact_shipments_carrier_idx ON analytics.fact_shipments (carrier_key);
CREATE INDEX fact_shipments_warehouse_idx ON analytics.fact_shipments (warehouse_key);
CREATE INDEX fact_inventory_date_idx ON analytics.fact_inventory (inventory_date_key);
CREATE INDEX fact_inventory_product_idx ON analytics.fact_inventory (product_key);
CREATE INDEX fact_inventory_warehouse_idx ON analytics.fact_inventory (warehouse_key);

ANALYZE analytics.dim_date;
ANALYZE analytics.dim_product;
ANALYZE analytics.dim_customer;
ANALYZE analytics.dim_warehouse;
ANALYZE analytics.dim_carrier;
ANALYZE analytics.fact_orders;
ANALYZE analytics.fact_shipments;
ANALYZE analytics.fact_inventory;
