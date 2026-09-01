\set ON_ERROR_STOP on

CREATE OR REPLACE VIEW analytics.vw_order_fulfilment AS
WITH parameters AS (
    SELECT date_value AS analysis_date
    FROM analytics.project_parameters
    WHERE parameter_name = 'analysis_date'
)
SELECT o.order_id,
       o.order_date,
       o.promised_delivery_date,
       o.order_status,
       o.order_quantity,
       o.order_value_eur,
       o.sales_channel,
       o.customer_id,
       c.customer_segment,
       c.country AS customer_country,
       o.product_id,
       p.product_name,
       p.product_category,
       o.warehouse_id,
       w.warehouse_name,
       w.city AS warehouse_city,
       w.daily_order_capacity,
       s.shipment_id,
       s.carrier_id,
       ca.carrier_name,
       ca.service_level,
       s.ship_date,
       s.actual_delivery_date,
       s.shipment_status,
       s.shipping_cost_eur,
       s.exception_reason,
       CASE
           WHEN s.actual_delivery_date IS NOT NULL AND o.promised_delivery_date IS NOT NULL
           THEN s.actual_delivery_date - o.promised_delivery_date
       END AS delivery_delay_days,
       CASE
           WHEN s.actual_delivery_date IS NOT NULL AND o.promised_delivery_date IS NOT NULL
           THEN s.actual_delivery_date <= o.promised_delivery_date
       END AS is_on_time,
       CASE
           WHEN s.ship_date IS NOT NULL THEN s.ship_date - o.order_date
       END AS fulfilment_lead_time_days,
       o.order_status NOT IN ('Delivered', 'Cancelled')
           AND s.shipment_id IS NULL AS is_backlog,
       CASE
           WHEN o.order_status NOT IN ('Delivered', 'Cancelled') AND s.shipment_id IS NULL
           THEN parameters.analysis_date - o.order_date
       END AS backlog_age_days,
       COALESCE(
           o.order_status <> 'Cancelled'
               AND o.promised_delivery_date IS NOT NULL
               AND (
                   s.actual_delivery_date > o.promised_delivery_date
                   OR (s.actual_delivery_date IS NULL AND parameters.analysis_date > o.promised_delivery_date)
               ),
           false
       ) AS is_sla_breach,
       o.is_analysis_eligible AS order_is_analysis_eligible,
       COALESCE(s.is_analysis_eligible, true) AS shipment_is_analysis_eligible,
       o.is_analysis_eligible AND COALESCE(s.is_analysis_eligible, true) AS fulfilment_is_analysis_eligible,
       parameters.analysis_date
FROM clean.orders o
LEFT JOIN clean.shipments s
    ON s.order_id = o.order_id
   AND s.has_order_mapping
LEFT JOIN clean.customers c ON c.customer_id = o.customer_id
LEFT JOIN clean.products p ON p.product_id = o.product_id
LEFT JOIN clean.warehouses w ON w.warehouse_id = o.warehouse_id
LEFT JOIN clean.carriers ca ON ca.carrier_id = s.carrier_id
CROSS JOIN parameters;

CREATE OR REPLACE VIEW analytics.vw_executive_kpis AS
WITH eligible_orders AS (
    SELECT *
    FROM clean.orders
    WHERE is_analysis_eligible
), fulfilment AS (
    SELECT *
    FROM analytics.vw_order_fulfilment
    WHERE fulfilment_is_analysis_eligible
), order_metrics AS (
    SELECT COUNT(*) AS total_orders,
           COUNT(*) FILTER (WHERE order_status <> 'Cancelled') AS revenue_order_count,
           SUM(order_value_eur) FILTER (WHERE order_status <> 'Cancelled') AS total_revenue_eur
    FROM eligible_orders
), fulfilment_metrics AS (
    SELECT COUNT(*) FILTER (WHERE is_backlog) AS open_backlog,
           COUNT(*) FILTER (WHERE is_backlog AND backlog_age_days > 3) AS backlog_over_3_days,
           COUNT(*) FILTER (WHERE is_backlog AND backlog_age_days > 7) AS backlog_over_7_days,
           COUNT(*) FILTER (WHERE is_sla_breach) AS sla_breach_orders,
           COUNT(*) FILTER (WHERE order_status <> 'Cancelled' AND promised_delivery_date IS NOT NULL) AS sla_eligible_orders,
           AVG(fulfilment_lead_time_days) FILTER (WHERE fulfilment_lead_time_days IS NOT NULL) AS avg_fulfilment_lead_time_days
    FROM fulfilment
), shipment_metrics AS (
    SELECT COUNT(*) FILTER (WHERE shipment_id IS NOT NULL) AS total_shipments,
           COUNT(*) FILTER (WHERE actual_delivery_date IS NOT NULL) AS delivered_shipments,
           COUNT(*) FILTER (WHERE is_on_time) AS on_time_deliveries,
           COUNT(*) FILTER (WHERE is_on_time = false) AS late_deliveries,
           AVG(GREATEST(delivery_delay_days, 0)) FILTER (WHERE actual_delivery_date IS NOT NULL) AS avg_delivery_delay_days,
           COUNT(*) FILTER (WHERE shipment_id IS NOT NULL AND exception_reason IS NOT NULL) AS shipments_with_exception
    FROM fulfilment
), inventory_daily AS (
    SELECT i.inventory_date,
           SUM(i.closing_stock * p.unit_cost_eur) AS closing_inventory_value_eur
    FROM clean.inventory i
    JOIN clean.products p ON p.product_id = i.product_id
    WHERE i.is_analysis_eligible
    GROUP BY i.inventory_date
), inventory_metrics AS (
    SELECT COUNT(*) AS valid_inventory_snapshots,
           COUNT(*) FILTER (WHERE closing_stock = 0) AS stockout_snapshots,
           SUM(shipped_quantity) AS warehouse_throughput_units,
           SUM(shipped_quantity * p.unit_cost_eur) AS shipped_cost_of_goods_eur
    FROM clean.inventory i
    JOIN clean.products p ON p.product_id = i.product_id
    WHERE i.is_analysis_eligible
), average_inventory AS (
    SELECT AVG(closing_inventory_value_eur) AS average_inventory_value_eur
    FROM inventory_daily
)
SELECT om.total_orders,
       sm.total_shipments,
       ROUND(om.total_revenue_eur, 2) AS total_revenue_eur,
       ROUND(om.total_revenue_eur / NULLIF(om.revenue_order_count, 0), 2) AS average_order_value_eur,
       ROUND(100.0 * sm.on_time_deliveries / NULLIF(sm.delivered_shipments, 0), 2) AS on_time_delivery_pct,
       ROUND(100.0 * sm.late_deliveries / NULLIF(sm.delivered_shipments, 0), 2) AS late_delivery_pct,
       ROUND(sm.avg_delivery_delay_days, 2) AS average_delivery_delay_days,
       ROUND(fm.avg_fulfilment_lead_time_days, 2) AS average_fulfilment_lead_time_days,
       fm.open_backlog,
       fm.backlog_over_3_days,
       fm.backlog_over_7_days,
       ROUND(100.0 * fm.sla_breach_orders / NULLIF(fm.sla_eligible_orders, 0), 2) AS sla_breach_pct,
       im.warehouse_throughput_units,
       ROUND(100.0 * im.stockout_snapshots / NULLIF(im.valid_inventory_snapshots, 0), 2) AS stockout_rate_pct,
       ROUND(im.shipped_cost_of_goods_eur / NULLIF(ai.average_inventory_value_eur, 0), 2) AS inventory_turnover_ratio,
       ROUND(100.0 * sm.shipments_with_exception / NULLIF(sm.total_shipments, 0), 2) AS exception_rate_pct
FROM order_metrics om
CROSS JOIN fulfilment_metrics fm
CROSS JOIN shipment_metrics sm
CROSS JOIN inventory_metrics im
CROSS JOIN average_inventory ai;

COMMENT ON VIEW analytics.vw_executive_kpis IS
'One-row KPI summary based only on records that pass documented eligibility rules. Percentages are returned on a 0–100 scale.';

TABLE analytics.vw_executive_kpis;
