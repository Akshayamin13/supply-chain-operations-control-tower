# Four-page dashboard specification

## Design principles

- 16:9 canvas with a light neutral background.
- Dark navy headers, teal for healthy performance, amber for warning, and red only for material exceptions.
- Six or fewer prominent KPIs per page.
- Consistent slicers: date, warehouse, product category, customer segment; carrier only where relevant.
- Use tooltips and drill-through for detail instead of crowding the overview.
- Show metric definitions in an information tooltip.

## Page 1 — Executive Overview

**Purpose:** Give an operations leader a one-minute health check.

Top KPI cards:

- Total Orders
- Revenue
- On-Time Delivery %
- Open Backlog
- SLA Breach %
- Stockout Rate

Visuals:

1. Monthly orders and revenue — combo chart using `DimDate[year_month]`.
2. Warehouse on-time delivery — sorted horizontal bar chart with a company-average reference line.
3. Carrier on-time performance versus average shipping cost — scatter plot.
4. Exception reasons — sorted bar chart, not a pie chart.
5. Small alert table — high-risk orders with conditional formatting.

## Page 2 — Fulfilment & Delivery

**Purpose:** Explain where and why deliveries are late.

KPI cards:

- Delivered Shipments
- Late Delivery %
- Average Delay Days
- Average Fulfilment Lead Time
- Backlog > 7 Days

Visuals:

1. Backlog ageing buckets — ordered column chart.
2. Warehouse delivery matrix — orders, OTD %, average delay, exceptions, backlog.
3. Carrier performance — OTD %, average delay, cost, service level.
4. Exception trend by month and reason — stacked column or small multiples.
5. Drill-through table — order, promise, shipment, carrier, exception, and delay days.

## Page 3 — Inventory

**Purpose:** Identify products and warehouses creating service risk.

KPI cards:

- Warehouse Throughput Units
- Stockout Rate
- Stockout Snapshots
- Inventory Turnover
- Products Below Reorder Level

Visuals:

1. Product risk matrix — shipped units versus stockout rate, category as legend.
2. Stockout trend — line chart by inventory month.
3. Warehouse × category heatmap — stockout rate with conditional formatting.
4. Below-reorder table — product, warehouse, closing stock, reorder level, supplier lead time.
5. Stockout association callout — late rate and lead time for stockout versus available stock.

## Page 4 — Operations Diagnostics

**Purpose:** Support root-cause investigation and prioritised action.

Visuals:

1. Capacity utilisation by warehouse — average, peak, and days over capacity.
2. Root-cause decomposition — warehouse → carrier → exception → category.
3. High-risk order table — prioritised by Critical, High, Medium.
4. Enterprise service view — revenue, order value, OTD, and backlog by segment.
5. Management action panel — short text summaries tied to filters.

## Interactions

- Warehouse selection filters every visual except the company trend where comparison is useful.
- Carrier selection affects shipment visuals but not inventory metrics.
- Product category affects order, shipment, and inventory facts through `DimProduct`.
- Date selection uses active relationships; alternate promised/actual-date views should use dedicated measures with `USERELATIONSHIP`.

## Reconciliation before screenshots

The first unfiltered Power BI values must match `data/processed/executive_kpis.csv`. If they do not, check data types, active relationships, boolean imports, Unknown rows, and measure denominators before formatting visuals.
