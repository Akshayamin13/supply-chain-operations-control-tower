\set ON_ERROR_STOP on

-- 1. SELECT, FROM, WHERE, ORDER BY, LIMIT
-- Business question: Which open orders require immediate attention?
SELECT order_id,
       warehouse_name,
       order_value_eur,
       backlog_age_days
FROM analytics.vw_high_risk_orders
WHERE risk_priority IN ('Critical', 'High')
ORDER BY backlog_age_days DESC NULLS LAST, order_value_eur DESC
LIMIT 20;

-- 2. DISTINCT
-- Business question: Which standardised order statuses exist after cleaning?
SELECT DISTINCT order_status
FROM clean.orders
ORDER BY order_status;

-- 3. CASE WHEN, GROUP BY, COUNT, SUM, AVG, MIN, MAX, HAVING
-- Business question: Which warehouses have enough volume to compare reliably?
SELECT w.warehouse_name,
       COUNT(*) AS orders,
       SUM(o.order_quantity) AS ordered_units,
       ROUND(AVG(o.order_value_eur), 2) AS average_order_value_eur,
       MIN(o.order_date) AS first_order_date,
       MAX(o.order_date) AS last_order_date,
       CASE
           WHEN COUNT(*) >= 5_000 THEN 'High volume'
           WHEN COUNT(*) >= 4_000 THEN 'Medium volume'
           ELSE 'Lower volume'
       END AS volume_band
FROM clean.orders o
INNER JOIN clean.warehouses w ON w.warehouse_id = o.warehouse_id
WHERE o.is_analysis_eligible
GROUP BY w.warehouse_name
HAVING COUNT(*) >= 3_000
ORDER BY orders DESC;

-- 4. LEFT JOIN and NULL handling
-- Business question: Which valid orders have no shipment?
SELECT o.order_id,
       o.order_date,
       o.order_status,
       COALESCE(s.shipment_status, 'Not shipped') AS shipment_status
FROM clean.orders o
LEFT JOIN clean.shipments s ON s.order_id = o.order_id
WHERE o.is_analysis_eligible
  AND s.shipment_id IS NULL
ORDER BY o.order_date
LIMIT 20;

-- 5. CTE and subquery
-- Business question: Which warehouses perform below the company on-time average?
WITH company_average AS (
    SELECT on_time_delivery_pct
    FROM analytics.vw_executive_kpis
)
SELECT warehouse_name,
       on_time_delivery_pct,
       on_time_delivery_pct - (SELECT on_time_delivery_pct FROM company_average) AS difference_from_company_pct_points
FROM analytics.vw_warehouse_performance
WHERE on_time_delivery_pct < (SELECT on_time_delivery_pct FROM company_average)
ORDER BY on_time_delivery_pct;

-- 6. Date functions
-- Business question: How do order volume and revenue change by calendar month?
SELECT DATE_TRUNC('month', order_date)::date AS order_month,
       COUNT(*) AS orders,
       ROUND(SUM(order_value_eur) FILTER (WHERE order_status <> 'Cancelled'), 2) AS revenue_eur
FROM clean.orders
WHERE is_analysis_eligible
GROUP BY DATE_TRUNC('month', order_date)::date
ORDER BY order_month;

-- 7. ROW_NUMBER
-- Business question: Which raw order rows are duplicates of the same business key?
WITH ranked_orders AS (
    SELECT order_id,
           source_row_id,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY source_row_id) AS duplicate_rank
    FROM raw.orders
)
SELECT order_id, source_row_id, duplicate_rank
FROM ranked_orders
WHERE duplicate_rank > 1
ORDER BY order_id;

-- 8. RANK
-- Business question: How do carriers rank by on-time performance within service level?
CREATE OR REPLACE VIEW analytics.vw_carrier_ranked AS
SELECT carrier_id,
       carrier_name,
       service_level,
       shipments,
       on_time_delivery_pct,
       RANK() OVER (
           PARTITION BY service_level
           ORDER BY on_time_delivery_pct DESC
       ) AS service_level_rank,
       RANK() OVER (ORDER BY on_time_delivery_pct DESC) AS company_rank
FROM analytics.vw_carrier_performance;

-- 9. LAG, LEAD, and running-total window functions
-- Business question: How did monthly demand change, what follows, and what is cumulative volume?
CREATE OR REPLACE VIEW analytics.vw_monthly_trend_with_change AS
SELECT order_month,
       total_orders,
       revenue_eur,
       LAG(total_orders) OVER (ORDER BY order_month) AS previous_month_orders,
       LEAD(total_orders) OVER (ORDER BY order_month) AS next_month_orders,
       total_orders - LAG(total_orders) OVER (ORDER BY order_month) AS month_over_month_order_change,
       ROUND(
           100.0 * (total_orders - LAG(total_orders) OVER (ORDER BY order_month))
           / NULLIF(LAG(total_orders) OVER (ORDER BY order_month), 0),
           2
       ) AS month_over_month_change_pct,
       SUM(total_orders) OVER (
           ORDER BY order_month
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS cumulative_orders
FROM analytics.vw_monthly_order_trend;

SELECT *
FROM analytics.vw_carrier_ranked
ORDER BY company_rank;

SELECT *
FROM analytics.vw_monthly_trend_with_change
ORDER BY order_month;

