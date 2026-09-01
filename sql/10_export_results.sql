\set ON_ERROR_STOP on

-- psql client-side exports. Run from the repository root.
\copy (SELECT * FROM analytics.vw_executive_kpis) TO 'data/processed/executive_kpis.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.vw_monthly_order_trend ORDER BY order_month) TO 'data/processed/monthly_order_trend.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.vw_warehouse_performance ORDER BY on_time_delivery_pct) TO 'data/processed/warehouse_performance.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.vw_carrier_performance ORDER BY on_time_delivery_pct) TO 'data/processed/carrier_performance.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.vw_exception_analysis ORDER BY affected_shipments DESC) TO 'data/processed/exception_analysis.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.vw_backlog_ageing ORDER BY bucket_sort) TO 'data/processed/backlog_ageing.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.vw_stockout_delay_association ORDER BY stock_position) TO 'data/processed/stockout_delay_association.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.vw_product_inventory_risk ORDER BY stockout_rate_pct DESC, shipped_units DESC) TO 'data/processed/product_inventory_risk.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.vw_warehouse_capacity ORDER BY days_over_capacity DESC) TO 'data/processed/warehouse_capacity.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.vw_customer_segment_performance ORDER BY revenue_eur DESC) TO 'data/processed/customer_segment_performance.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy (SELECT * FROM analytics.vw_high_risk_orders ORDER BY CASE risk_priority WHEN 'Critical' THEN 1 WHEN 'High' THEN 2 WHEN 'Medium' THEN 3 ELSE 4 END, backlog_age_days DESC NULLS LAST LIMIT 500) TO 'data/processed/high_risk_orders.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
