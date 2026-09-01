\set ON_ERROR_STOP on

CREATE OR REPLACE VIEW analytics.vw_monthly_order_trend AS
SELECT DATE_TRUNC('month', order_date)::date AS order_month,
       COUNT(*) AS total_orders,
       COUNT(*) FILTER (WHERE order_status <> 'Cancelled') AS non_cancelled_orders,
       SUM(order_quantity) FILTER (WHERE order_status <> 'Cancelled') AS ordered_units,
       ROUND(SUM(order_value_eur) FILTER (WHERE order_status <> 'Cancelled'), 2) AS revenue_eur,
       ROUND(AVG(order_value_eur) FILTER (WHERE order_status <> 'Cancelled'), 2) AS average_order_value_eur
FROM clean.orders
WHERE is_analysis_eligible
GROUP BY DATE_TRUNC('month', order_date)::date;

CREATE OR REPLACE VIEW analytics.vw_warehouse_performance AS
SELECT warehouse_id,
       warehouse_name,
       warehouse_city,
       COUNT(*) AS eligible_orders,
       COUNT(*) FILTER (WHERE shipment_id IS NOT NULL) AS shipments,
       COUNT(*) FILTER (WHERE actual_delivery_date IS NOT NULL) AS delivered_shipments,
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time)
           / NULLIF(COUNT(*) FILTER (WHERE actual_delivery_date IS NOT NULL), 0), 2) AS on_time_delivery_pct,
       ROUND(AVG(GREATEST(delivery_delay_days, 0)) FILTER (WHERE actual_delivery_date IS NOT NULL), 2) AS average_delay_days,
       COUNT(*) FILTER (WHERE is_backlog) AS open_backlog,
       COUNT(*) FILTER (WHERE is_sla_breach) AS sla_breaches,
       ROUND(100.0 * COUNT(*) FILTER (WHERE exception_reason IS NOT NULL)
           / NULLIF(COUNT(*) FILTER (WHERE shipment_id IS NOT NULL), 0), 2) AS exception_rate_pct,
       ROUND(SUM(order_value_eur) FILTER (WHERE order_status <> 'Cancelled'), 2) AS revenue_eur
FROM analytics.vw_order_fulfilment
WHERE fulfilment_is_analysis_eligible
GROUP BY warehouse_id, warehouse_name, warehouse_city;

CREATE OR REPLACE VIEW analytics.vw_carrier_performance AS
SELECT carrier_id,
       COALESCE(carrier_name, 'Unknown Carrier') AS carrier_name,
       COALESCE(service_level, 'Unknown') AS service_level,
       COUNT(*) AS shipments,
       COUNT(*) FILTER (WHERE actual_delivery_date IS NOT NULL) AS delivered_shipments,
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time)
           / NULLIF(COUNT(*) FILTER (WHERE actual_delivery_date IS NOT NULL), 0), 2) AS on_time_delivery_pct,
       ROUND(AVG(GREATEST(delivery_delay_days, 0)) FILTER (WHERE actual_delivery_date IS NOT NULL), 2) AS average_delay_days,
       ROUND(100.0 * COUNT(*) FILTER (WHERE exception_reason IS NOT NULL)
           / NULLIF(COUNT(*), 0), 2) AS exception_rate_pct,
       ROUND(SUM(shipping_cost_eur), 2) AS shipping_cost_eur,
       ROUND(AVG(shipping_cost_eur), 2) AS average_shipping_cost_eur
FROM analytics.vw_order_fulfilment
WHERE fulfilment_is_analysis_eligible
  AND shipment_id IS NOT NULL
GROUP BY carrier_id, COALESCE(carrier_name, 'Unknown Carrier'), COALESCE(service_level, 'Unknown');

CREATE OR REPLACE VIEW analytics.vw_exception_analysis AS
SELECT exception_reason,
       COUNT(*) AS affected_shipments,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_of_exceptions_pct,
       ROUND(AVG(GREATEST(delivery_delay_days, 0)), 2) AS average_delay_days,
       COUNT(*) FILTER (WHERE is_on_time = false) AS late_deliveries
FROM analytics.vw_order_fulfilment
WHERE fulfilment_is_analysis_eligible
  AND shipment_id IS NOT NULL
  AND exception_reason IS NOT NULL
GROUP BY exception_reason;

CREATE OR REPLACE VIEW analytics.vw_backlog_ageing AS
SELECT CASE
           WHEN backlog_age_days <= 3 THEN '0–3 days'
           WHEN backlog_age_days <= 7 THEN '4–7 days'
           WHEN backlog_age_days <= 14 THEN '8–14 days'
           ELSE '15+ days'
       END AS backlog_bucket,
       CASE
           WHEN backlog_age_days <= 3 THEN 1
           WHEN backlog_age_days <= 7 THEN 2
           WHEN backlog_age_days <= 14 THEN 3
           ELSE 4
       END AS bucket_sort,
       COUNT(*) AS backlog_orders,
       ROUND(SUM(order_value_eur), 2) AS backlog_value_eur,
       ROUND(AVG(backlog_age_days), 1) AS average_age_days
FROM analytics.vw_order_fulfilment
WHERE fulfilment_is_analysis_eligible
  AND is_backlog
GROUP BY 1, 2;

CREATE OR REPLACE VIEW analytics.vw_stockout_delay_association AS
SELECT CASE WHEN i.closing_stock = 0 THEN 'Stockout on order date' ELSE 'Stock available' END AS stock_position,
       COUNT(*) AS orders,
       COUNT(*) FILTER (WHERE f.actual_delivery_date IS NOT NULL) AS delivered_orders,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.is_on_time = false)
           / NULLIF(COUNT(*) FILTER (WHERE f.actual_delivery_date IS NOT NULL), 0), 2) AS late_delivery_pct,
       ROUND(AVG(GREATEST(f.delivery_delay_days, 0)) FILTER (WHERE f.actual_delivery_date IS NOT NULL), 2) AS average_delay_days,
       ROUND(AVG(f.fulfilment_lead_time_days) FILTER (WHERE f.fulfilment_lead_time_days IS NOT NULL), 2) AS average_fulfilment_lead_time_days
FROM analytics.vw_order_fulfilment f
JOIN clean.inventory i
  ON i.inventory_date = f.order_date
 AND i.warehouse_id = f.warehouse_id
 AND i.product_id = f.product_id
WHERE f.fulfilment_is_analysis_eligible
  AND i.is_analysis_eligible
  AND f.order_status <> 'Cancelled'
GROUP BY CASE WHEN i.closing_stock = 0 THEN 'Stockout on order date' ELSE 'Stock available' END;

CREATE OR REPLACE VIEW analytics.vw_product_inventory_risk AS
SELECT p.product_id,
       p.product_name,
       p.product_category,
       COUNT(*) AS valid_snapshot_days,
       COUNT(*) FILTER (WHERE i.closing_stock = 0) AS stockout_snapshots,
       ROUND(100.0 * COUNT(*) FILTER (WHERE i.closing_stock = 0) / NULLIF(COUNT(*), 0), 2) AS stockout_rate_pct,
       COUNT(*) FILTER (WHERE i.closing_stock <= i.reorder_level) AS below_reorder_snapshots,
       SUM(i.shipped_quantity) AS shipped_units,
       ROUND(AVG(i.closing_stock), 2) AS average_closing_stock
FROM clean.inventory i
JOIN clean.products p ON p.product_id = i.product_id
WHERE i.is_analysis_eligible
GROUP BY p.product_id, p.product_name, p.product_category;

CREATE OR REPLACE VIEW analytics.vw_warehouse_capacity AS
WITH daily_orders AS (
    SELECT order_date,
           warehouse_id,
           COUNT(*) AS orders_processed
    FROM clean.orders
    WHERE is_analysis_eligible
      AND order_status <> 'Cancelled'
    GROUP BY order_date, warehouse_id
), daily_capacity AS (
    SELECT d.order_date,
           w.warehouse_id,
           w.warehouse_name,
           w.city,
           w.daily_order_capacity,
           d.orders_processed,
           d.orders_processed::numeric / w.daily_order_capacity AS utilisation_ratio
    FROM daily_orders d
    JOIN clean.warehouses w ON w.warehouse_id = d.warehouse_id
)
SELECT warehouse_id,
       warehouse_name,
       city,
       daily_order_capacity,
       ROUND(100.0 * AVG(utilisation_ratio), 2) AS average_capacity_utilisation_pct,
       ROUND(100.0 * MAX(utilisation_ratio), 2) AS peak_capacity_utilisation_pct,
       COUNT(*) FILTER (WHERE utilisation_ratio > 0.90) AS days_above_90_pct,
       COUNT(*) FILTER (WHERE utilisation_ratio > 1.00) AS days_over_capacity
FROM daily_capacity
GROUP BY warehouse_id, warehouse_name, city, daily_order_capacity;

CREATE OR REPLACE VIEW analytics.vw_customer_segment_performance AS
SELECT customer_segment,
       COUNT(*) AS orders,
       SUM(order_quantity) AS ordered_units,
       ROUND(SUM(order_value_eur) FILTER (WHERE order_status <> 'Cancelled'), 2) AS revenue_eur,
       ROUND(AVG(order_value_eur) FILTER (WHERE order_status <> 'Cancelled'), 2) AS average_order_value_eur,
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time)
           / NULLIF(COUNT(*) FILTER (WHERE actual_delivery_date IS NOT NULL), 0), 2) AS on_time_delivery_pct
FROM analytics.vw_order_fulfilment
WHERE fulfilment_is_analysis_eligible
GROUP BY customer_segment;

CREATE OR REPLACE VIEW analytics.vw_high_risk_orders AS
SELECT order_id,
       order_date,
       promised_delivery_date,
       order_status,
       warehouse_name,
       customer_segment,
       product_name,
       order_value_eur,
       backlog_age_days,
       is_sla_breach,
       CASE
           WHEN is_backlog AND backlog_age_days > 14 THEN 'Critical'
           WHEN is_backlog AND backlog_age_days > 7 THEN 'High'
           WHEN is_sla_breach THEN 'High'
           WHEN is_backlog AND backlog_age_days > 3 THEN 'Medium'
           ELSE 'Monitor'
       END AS risk_priority
FROM analytics.vw_order_fulfilment
WHERE fulfilment_is_analysis_eligible
  AND (is_backlog OR is_sla_breach);

