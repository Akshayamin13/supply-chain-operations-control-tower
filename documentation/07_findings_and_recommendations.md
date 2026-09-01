# Findings and recommendations

These findings describe a deterministic synthetic scenario. They demonstrate analytical reasoning but do not claim real employer impact or prove causation.

## 1. Cologne is the main warehouse performance risk

**Observation:** Rhine-Ruhr Fulfilment Centre has the weakest delivery reliability.

**Evidence:** On-time delivery is 55.62%, versus 66.15% for the strongest warehouse, Hamburg. Cologne also has the highest exception rate at 36.81% and 117 days above daily capacity.

**Possible cause:** Its average capacity utilisation is 87.56%, and it exceeds planned daily capacity more often than any other site.

**Business implication:** Continued routing into Cologne is likely to enlarge backlog and increase late deliveries during peaks.

**Recommended action:** Rebalance demand to nearby capacity, review shift coverage, and trigger an exception when forecast volume exceeds 90% of daily capacity.

## 2. Warehouse capacity dominates recorded exceptions

**Observation:** Capacity pressure is the largest named operational exception.

**Evidence:** `Warehouse Capacity` accounts for 4,709 shipments, 59.00% of all recorded exceptions, with 3,822 late deliveries and an average two-day delay.

**Possible cause:** Seasonal volume and warehouse allocation exceed the simulated processing limits on many days.

**Business implication:** Carrier changes alone cannot resolve most exceptions because the dominant issue occurs before hand-off.

**Recommended action:** Add a daily capacity forecast, a 90% warning threshold, and routing rules that consider available warehouse capacity before order assignment.

## 3. Economy carriers show a clear cost–service trade-off

**Observation:** Economy services cost less but deliver substantially weaker on-time performance.

**Evidence:** Alpine Freight and EuroLink Standard achieve 27.98% and 30.81% on-time delivery at average costs of €4.19 and €4.33. Mainline Express and RapidRoute achieve 86.09% and 85.90% at €9.41 and €9.12.

**Possible cause:** The synthetic economy services have longer base transit times and higher disruption risk.

**Business implication:** Applying economy routing uniformly can expose time-sensitive or high-value orders to avoidable SLA risk.

**Recommended action:** Use service-tier rules: reserve express for high-value, enterprise, or already-at-risk orders, then test the incremental cost against SLA improvement.

## 4. Stockouts are strongly associated with delay

**Observation:** Orders placed when the warehouse-product combination closes at zero stock are far more likely to be late.

**Evidence:** The late-delivery rate is 96.70% for 345 stockout-linked orders versus 36.98% when stock is available. Average delay rises from 0.73 to 3.86 days, and fulfilment lead time rises from 1.38 to 5.04 days.

**Possible cause:** Replenishment must arrive before the affected order can be handed to a carrier.

**Business implication:** A low overall stockout rate can still create concentrated service failures on high-demand products.

**Recommended action:** Prioritise reorder policies for products with both high demand and repeated stockouts; track the result by warehouse-product combination.

## 5. Most backlog is severely aged

**Observation:** The backlog problem is concentrated in old orders rather than only recent workflow.

**Evidence:** Of 688 open backlog orders, 464 are aged 15+ days. This group has an average age of 179.4 days and €52,374.40 in order value.

**Possible cause:** A small population of historic Processing and On Hold orders was never resolved in the simulated lifecycle.

**Business implication:** Aggregate backlog can remain high even if new orders flow normally because stale records never close.

**Recommended action:** Create a daily aged-backlog queue with named ownership, reason codes, and closure/escalation rules for orders older than seven days.

## 6. December demand creates a visible seasonal peak

**Observation:** Order volume peaks sharply in December.

**Evidence:** December contains 3,884 eligible orders, compared with 2,183 in September and 2,075 in January.

**Possible cause:** The synthetic demand model includes a year-end retail peak.

**Business implication:** Static staffing and carrier allocation are unlikely to provide consistent service through the peak.

**Recommended action:** Use the monthly trend as the starting point for capacity, replenishment, and carrier-volume planning before November.

## 7. Enterprise orders combine high value with weaker service

**Observation:** Enterprise orders have the highest average value but the lowest delivery reliability by customer segment.

**Evidence:** Enterprise average order value is €422.40 and on-time delivery is 54.93%; the other segments are near 62–63% on time.

**Possible cause:** Enterprise orders contain larger quantities, increasing inventory and handling exposure.

**Business implication:** Service failures are concentrated on commercially important demand.

**Recommended action:** Apply inventory reservation and priority fulfilment rules for enterprise orders, then monitor service separately from consumer volume.

## 8. Inventory risk is concentrated in specific products

**Observation:** A small set of products accounts for the highest repeated stockout exposure.

**Evidence:** Kitchen Scale 09 records 52 stockout snapshots (2.37%), and Electric Toothbrush 01 records 48 (2.19%). Wireless Mouse 01 combines 22 stockout snapshots with 1,131 shipped units.

**Possible cause:** Reorder levels and replenishment frequency are not equally suited to each product's demand pattern.

**Business implication:** A company-wide average can hide SKU-specific service risk.

**Recommended action:** Review reorder levels using product demand, supplier lead time, and warehouse-specific stockout frequency instead of one blanket threshold.
