# KPI catalogue

All values describe the synthetic scenario as of 2026-09-01. Percentages use a 0–100 display scale.

| KPI | Business meaning | Calculation and denominator | Validated result |
|---|---|---|---:|
| Total Orders | Valid demand records received | Distinct clean orders passing order-level eligibility; cancelled orders included | 29,873 |
| Total Shipments | Valid shipment records linked to eligible orders | Distinct shipment IDs passing shipment/date and order eligibility | 28,366 |
| Total Revenue | Gross synthetic order value | Sum of eligible non-cancelled order value | €3,221,285.15 |
| Average Order Value | Typical value of a revenue-generating order | Revenue ÷ eligible non-cancelled orders | €110.71 |
| On-Time Delivery % | Reliability against the promised date | Delivered on/before promise ÷ delivered shipments with valid dates | 62.32% |
| Late Delivery % | Share delivered after promise | Late delivered shipments ÷ delivered shipments with valid dates | 37.68% |
| Average Delivery Delay | Typical lateness, without rewarding early delivery | Average of `max(actual − promised, 0)` for delivered shipments | 0.76 days |
| Order Fulfilment Lead Time | Time from order placement to carrier hand-off | Average `ship date − order date` for shipped eligible orders | 1.43 days |
| Open Backlog | Orders not cancelled/delivered and not yet shipped | Eligible orders meeting the backlog rule at the fixed reporting date | 688 |
| Backlog > 3 Days | Ageing operational workload | Open backlog where reporting date − order date > 3 | 553 |
| Backlog > 7 Days | Severe ageing workload | Open backlog where reporting date − order date > 7 | 499 |
| SLA Breach % | Orders delivered late or still overdue | Breached eligible orders ÷ non-cancelled eligible orders with a promise date | 38.78% |
| Warehouse Throughput | Units fulfilled from inventory | Sum of shipped quantity across valid inventory snapshots | 67,281 units |
| Stockout Rate | Frequency of zero closing stock | Valid snapshots with closing stock = 0 ÷ all valid snapshots | 0.35% |
| Inventory Turnover | Movement relative to average stock investment | Shipped cost of goods ÷ average daily closing inventory value | 4.30× |
| Exception Rate | Frequency of recorded operational disruption | Eligible shipments with an exception ÷ eligible shipments | 28.14% |
| Carrier On-Time Performance | Delivery reliability within the selected carrier context | Same on-time formula filtered by carrier | Context dependent |
| Warehouse On-Time Performance | Delivery reliability within the selected warehouse context | Same on-time formula filtered by warehouse | Context dependent |

## Important denominator lesson

Different KPIs require different eligibility rules. An order with an invalid shipment date still exists as an order, so it remains in order counts if its order fields are valid. That shipment is excluded only from delivery metrics. Using one universal filter would produce misleading totals.
