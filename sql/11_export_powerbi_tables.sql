\set ON_ERROR_STOP on

-- Compact reporting model for browser-first Power BI authoring on the Mac.
-- PostgreSQL retains the authoritative daily/full-grain star schema.

CREATE OR REPLACE VIEW analytics.vw_powerbi_order_summary AS
SELECT TO_CHAR(DATE_TRUNC('month', d.full_date), 'YYYYMMDD')::integer AS order_month_key,
       fo.warehouse_key,
       p.product_category,
       c.customer_segment,
       fo.order_status,
       CASE WHEN fo.is_backlog THEN 'TRUE' ELSE 'FALSE' END AS is_backlog,
       CASE
           WHEN fo.backlog_age_days IS NULL THEN 'Not Backlog'
           WHEN fo.backlog_age_days <= 3 THEN '0–3 days'
           WHEN fo.backlog_age_days <= 7 THEN '4–7 days'
           WHEN fo.backlog_age_days <= 14 THEN '8–14 days'
           ELSE '15+ days'
       END AS backlog_bucket,
       CASE WHEN fo.fulfilment_is_analysis_eligible AND fo.is_sla_breach THEN 'TRUE' ELSE 'FALSE' END AS is_sla_breach,
       COUNT(*) AS order_count,
       SUM(fo.order_quantity) AS ordered_units,
       ROUND(SUM(fo.order_value_eur), 2) AS order_value_eur,
       COUNT(*) FILTER (WHERE fo.fulfilment_is_analysis_eligible AND fo.is_sla_breach) AS sla_breach_order_count,
       COUNT(*) FILTER (
           WHERE fo.fulfilment_is_analysis_eligible
             AND fo.order_status <> 'Cancelled'
             AND fo.promised_delivery_date_key <> 0
       ) AS sla_eligible_order_count
FROM analytics.fact_orders fo
JOIN analytics.dim_date d ON d.date_key = fo.order_date_key
JOIN analytics.dim_product p ON p.product_key = fo.product_key
JOIN analytics.dim_customer c ON c.customer_key = fo.customer_key
WHERE fo.is_analysis_eligible
GROUP BY DATE_TRUNC('month', d.full_date), fo.warehouse_key, p.product_category,
         c.customer_segment, fo.order_status, fo.is_backlog,
         CASE
             WHEN fo.backlog_age_days IS NULL THEN 'Not Backlog'
             WHEN fo.backlog_age_days <= 3 THEN '0–3 days'
             WHEN fo.backlog_age_days <= 7 THEN '4–7 days'
             WHEN fo.backlog_age_days <= 14 THEN '8–14 days'
             ELSE '15+ days'
         END,
         fo.is_sla_breach, fo.fulfilment_is_analysis_eligible;

CREATE OR REPLACE VIEW analytics.vw_powerbi_shipment_summary AS
SELECT TO_CHAR(DATE_TRUNC('month', d.full_date), 'YYYYMMDD')::integer AS ship_month_key,
       fs.warehouse_key,
       fs.carrier_key,
       p.product_category,
       fs.shipment_status,
       COALESCE(fs.exception_reason, 'No Exception') AS exception_reason,
       COUNT(*) AS shipment_count,
       COUNT(*) FILTER (WHERE fs.actual_delivery_date_key <> 0) AS delivered_shipment_count,
       COUNT(*) FILTER (WHERE fs.is_on_time) AS on_time_delivery_count,
       COUNT(*) FILTER (WHERE fs.is_on_time = false) AS late_delivery_count,
       SUM(GREATEST(fs.delivery_delay_days, 0)) FILTER (WHERE fs.actual_delivery_date_key <> 0) AS delivery_delay_days_sum,
       COUNT(*) FILTER (WHERE fs.actual_delivery_date_key <> 0) AS delivery_delay_observation_count,
       SUM(fs.fulfilment_lead_time_days) FILTER (WHERE fs.fulfilment_lead_time_days IS NOT NULL) AS fulfilment_lead_time_days_sum,
       COUNT(*) FILTER (WHERE fs.fulfilment_lead_time_days IS NOT NULL) AS fulfilment_lead_time_observation_count,
       ROUND(SUM(fs.shipping_cost_eur), 2) AS shipping_cost_eur
FROM analytics.fact_shipments fs
JOIN analytics.dim_date d ON d.date_key = fs.ship_date_key
JOIN analytics.dim_product p ON p.product_key = fs.product_key
WHERE fs.is_analysis_eligible
GROUP BY DATE_TRUNC('month', d.full_date), fs.warehouse_key, fs.carrier_key,
         p.product_category, fs.shipment_status, COALESCE(fs.exception_reason, 'No Exception');

CREATE OR REPLACE VIEW analytics.vw_powerbi_inventory_summary AS
SELECT TO_CHAR(DATE_TRUNC('month', d.full_date), 'YYYYMMDD')::integer AS inventory_month_key,
       fi.product_key,
       fi.warehouse_key,
       SUM(fi.received_quantity) AS received_quantity,
       SUM(fi.shipped_quantity) AS shipped_quantity,
       SUM(fi.closing_stock) AS closing_stock_day_sum,
       ROUND(AVG(fi.closing_stock), 2) AS average_closing_stock,
       MAX(fi.reorder_level) AS reorder_level,
       COUNT(*) AS valid_snapshot_count,
       COUNT(*) FILTER (WHERE fi.is_stockout) AS stockout_snapshot_count,
       COUNT(*) FILTER (WHERE fi.is_below_reorder) AS below_reorder_snapshot_count,
       COUNT(DISTINCT d.full_date) AS days_in_month,
       ROUND(SUM(fi.shipped_quantity * p.unit_cost_eur), 2) AS shipped_cogs_eur,
       ROUND(SUM(fi.closing_stock * p.unit_cost_eur), 2) AS closing_inventory_value_day_sum_eur
FROM analytics.fact_inventory fi
JOIN analytics.dim_date d ON d.date_key = fi.inventory_date_key
JOIN analytics.dim_product p ON p.product_key = fi.product_key
WHERE fi.is_analysis_eligible
GROUP BY DATE_TRUNC('month', d.full_date), fi.product_key, fi.warehouse_key;

CREATE OR REPLACE VIEW analytics.vw_powerbi_executive_kpis AS
WITH order_metrics AS (
    SELECT SUM(order_count) AS total_orders,
           SUM(order_count) FILTER (WHERE order_status <> 'Cancelled') AS revenue_order_count,
           SUM(order_value_eur) FILTER (WHERE order_status <> 'Cancelled') AS total_revenue_eur,
           SUM(order_count) FILTER (WHERE is_backlog = 'TRUE') AS open_backlog,
           SUM(order_count) FILTER (WHERE is_backlog = 'TRUE' AND backlog_bucket IN ('4–7 days', '8–14 days', '15+ days')) AS backlog_over_3_days,
           SUM(order_count) FILTER (WHERE is_backlog = 'TRUE' AND backlog_bucket IN ('8–14 days', '15+ days')) AS backlog_over_7_days,
           SUM(order_count) FILTER (WHERE is_sla_breach = 'TRUE') AS sla_breach_orders,
           SUM(sla_eligible_order_count) AS sla_eligible_orders
    FROM analytics.vw_powerbi_order_summary
), shipment_metrics AS (
    SELECT SUM(shipment_count) AS total_shipments,
           SUM(delivered_shipment_count) AS delivered_shipments,
           SUM(on_time_delivery_count) AS on_time_deliveries,
           SUM(late_delivery_count) AS late_deliveries,
           SUM(delivery_delay_days_sum) AS delay_days_sum,
           SUM(delivery_delay_observation_count) AS delay_observations,
           SUM(fulfilment_lead_time_days_sum) AS lead_time_days_sum,
           SUM(fulfilment_lead_time_observation_count) AS lead_time_observations,
           SUM(shipment_count) FILTER (WHERE exception_reason <> 'No Exception') AS shipments_with_exception
    FROM analytics.vw_powerbi_shipment_summary
), inventory_metrics AS (
    SELECT SUM(shipped_quantity) AS warehouse_throughput_units,
           SUM(stockout_snapshot_count) AS stockout_snapshots,
           SUM(valid_snapshot_count) AS valid_inventory_snapshots,
           SUM(shipped_cogs_eur) AS shipped_cost_of_goods_eur,
           SUM(closing_inventory_value_day_sum_eur) AS closing_inventory_value_day_sum_eur
    FROM analytics.vw_powerbi_inventory_summary
), represented_days AS (
    SELECT SUM(days_in_month) AS inventory_days
    FROM (
        SELECT inventory_month_key, MAX(days_in_month) AS days_in_month
        FROM analytics.vw_powerbi_inventory_summary
        GROUP BY inventory_month_key
    ) months
)
SELECT om.total_orders,
       sm.total_shipments,
       ROUND(om.total_revenue_eur, 2) AS total_revenue_eur,
       ROUND(om.total_revenue_eur / NULLIF(om.revenue_order_count, 0), 2) AS average_order_value_eur,
       ROUND(100.0 * sm.on_time_deliveries / NULLIF(sm.delivered_shipments, 0), 2) AS on_time_delivery_pct,
       ROUND(100.0 * sm.late_deliveries / NULLIF(sm.delivered_shipments, 0), 2) AS late_delivery_pct,
       ROUND(sm.delay_days_sum::numeric / NULLIF(sm.delay_observations, 0), 2) AS average_delivery_delay_days,
       ROUND(sm.lead_time_days_sum::numeric / NULLIF(sm.lead_time_observations, 0), 2) AS average_fulfilment_lead_time_days,
       om.open_backlog,
       om.backlog_over_3_days,
       om.backlog_over_7_days,
       ROUND(100.0 * om.sla_breach_orders / NULLIF(om.sla_eligible_orders, 0), 2) AS sla_breach_pct,
       im.warehouse_throughput_units,
       ROUND(100.0 * im.stockout_snapshots / NULLIF(im.valid_inventory_snapshots, 0), 2) AS stockout_rate_pct,
       ROUND(im.shipped_cost_of_goods_eur / NULLIF(im.closing_inventory_value_day_sum_eur / rd.inventory_days, 0), 2) AS inventory_turnover_ratio,
       ROUND(100.0 * sm.shipments_with_exception / NULLIF(sm.total_shipments, 0), 2) AS exception_rate_pct
FROM order_metrics om
CROSS JOIN shipment_metrics sm
CROSS JOIN inventory_metrics im
CROSS JOIN represented_days rd;

DROP TABLE IF EXISTS audit.powerbi_reconciliation_results;
CREATE TABLE audit.powerbi_reconciliation_results (
    metric_name text PRIMARY KEY,
    full_model_value numeric NOT NULL,
    browser_model_value numeric NOT NULL,
    tolerance numeric NOT NULL,
    check_status text NOT NULL,
    checked_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

WITH full_model AS (
    SELECT * FROM analytics.vw_executive_kpis
), browser_model AS (
    SELECT * FROM analytics.vw_powerbi_executive_kpis
), compared AS (
    SELECT comparison.*
    FROM full_model f
    CROSS JOIN browser_model b
    CROSS JOIN LATERAL (
        VALUES
            ('total_orders', f.total_orders::numeric, b.total_orders::numeric, 0::numeric),
            ('total_shipments', f.total_shipments::numeric, b.total_shipments::numeric, 0::numeric),
            ('total_revenue_eur', f.total_revenue_eur, b.total_revenue_eur, 0.01::numeric),
            ('average_order_value_eur', f.average_order_value_eur, b.average_order_value_eur, 0.01::numeric),
            ('on_time_delivery_pct', f.on_time_delivery_pct, b.on_time_delivery_pct, 0.01::numeric),
            ('late_delivery_pct', f.late_delivery_pct, b.late_delivery_pct, 0.01::numeric),
            ('average_delivery_delay_days', f.average_delivery_delay_days, b.average_delivery_delay_days, 0.01::numeric),
            ('average_fulfilment_lead_time_days', f.average_fulfilment_lead_time_days, b.average_fulfilment_lead_time_days, 0.01::numeric),
            ('open_backlog', f.open_backlog::numeric, b.open_backlog::numeric, 0::numeric),
            ('backlog_over_3_days', f.backlog_over_3_days::numeric, b.backlog_over_3_days::numeric, 0::numeric),
            ('backlog_over_7_days', f.backlog_over_7_days::numeric, b.backlog_over_7_days::numeric, 0::numeric),
            ('sla_breach_pct', f.sla_breach_pct, b.sla_breach_pct, 0.01::numeric),
            ('warehouse_throughput_units', f.warehouse_throughput_units::numeric, b.warehouse_throughput_units::numeric, 0::numeric),
            ('stockout_rate_pct', f.stockout_rate_pct, b.stockout_rate_pct, 0.01::numeric),
            ('inventory_turnover_ratio', f.inventory_turnover_ratio, b.inventory_turnover_ratio, 0.01::numeric),
            ('exception_rate_pct', f.exception_rate_pct, b.exception_rate_pct, 0.01::numeric)
    ) AS comparison(metric_name, full_model_value, browser_model_value, tolerance)
)
INSERT INTO audit.powerbi_reconciliation_results (
    metric_name, full_model_value, browser_model_value, tolerance, check_status
)
SELECT metric_name,
       full_model_value,
       browser_model_value,
       tolerance,
       CASE WHEN ABS(full_model_value - browser_model_value) <= tolerance THEN 'PASS' ELSE 'FAIL' END
FROM compared;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM audit.powerbi_reconciliation_results WHERE check_status = 'FAIL') THEN
        RAISE EXCEPTION 'Browser Power BI model does not reconcile to the full model. Inspect audit.powerbi_reconciliation_results.';
    END IF;
END $$;

\copy (SELECT * FROM analytics.dim_date ORDER BY date_key) TO 'data/tmp/powerbi_source/DimDate.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.dim_product ORDER BY product_key) TO 'data/tmp/powerbi_source/DimProduct.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.dim_warehouse ORDER BY warehouse_key) TO 'data/tmp/powerbi_source/DimWarehouse.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.dim_carrier ORDER BY carrier_key) TO 'data/tmp/powerbi_source/DimCarrier.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.vw_powerbi_order_summary ORDER BY order_month_key, warehouse_key, product_category, customer_segment) TO 'data/tmp/powerbi_source/OrderSummary.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.vw_powerbi_shipment_summary ORDER BY ship_month_key, warehouse_key, carrier_key, product_category) TO 'data/tmp/powerbi_source/ShipmentSummary.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.vw_powerbi_inventory_summary ORDER BY inventory_month_key, product_key, warehouse_key) TO 'data/tmp/powerbi_source/InventorySummary.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.vw_powerbi_executive_kpis) TO 'data/tmp/powerbi_source/ExecutiveKPIs.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

SELECT metric_name, full_model_value, browser_model_value, check_status
FROM audit.powerbi_reconciliation_results
ORDER BY metric_name;
