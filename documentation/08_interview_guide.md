# Interview guide

## What business problem does the project solve?

It combines disconnected order, shipment, inventory, warehouse, carrier, product, and customer data into one auditable model. The outputs help management monitor delivery reliability, backlog, stockout risk, capacity, exceptions, and the operational drivers of delay.

## Why PostgreSQL?

PostgreSQL provides explicit data types, constraints, repeatable SQL transformations, window functions, and relational joins. It lets the project demonstrate an auditable pipeline rather than manually editing spreadsheet data.

## Why preserve raw tables as text?

Raw text prevents an import from silently rejecting or converting dirty values. Data types are applied only in the clean layer after quality checks document what is wrong.

## Why use `ROW_NUMBER()`?

`ROW_NUMBER()` assigns a sequence within each business key. Keeping rank 1 makes the deduplication rule explicit and reproducible while the original copies remain in `raw`.

## Why use a `LEFT JOIN` from orders to shipments?

Some orders are cancelled or still waiting to ship. An inner join would remove them and make backlog analysis impossible. A left join keeps every order and adds shipment data where available.

## What is the grain of each fact table?

- `FactOrders`: one order.
- `FactShipments`: one shipment.
- `FactInventory`: one date × warehouse × product snapshot.

Declaring these grains prevents accidental double counting.

## Why three fact tables instead of one giant table?

Orders, shipments, and inventory occur at different grains. Joining daily inventory to orders in one physical table would repeat order values across many inventory rows. Separate facts preserve each event and share conformed dimensions.

## Why use surrogate keys?

Surrogate numeric keys isolate the analytics model from source-system identifiers, provide explicit Unknown members, and support future history handling without changing source business keys.

## How is on-time delivery calculated?

The numerator is delivered shipments where actual delivery is on or before the order's promised date. The denominator is delivered shipments with valid promise and delivery dates. Open shipments are excluded because they have not yet produced a final delivery outcome.

## How is backlog defined?

An eligible order is backlog when it is neither Delivered nor Cancelled and has no shipment. Age is the fixed reporting date minus order date, making the result reproducible.

## Why is total order eligibility different from shipment eligibility?

A shipment defect should not erase a valid order. Order KPIs use order-level checks; delivery KPIs additionally require valid shipment dates and mapping. This avoids contaminating unrelated denominators.

## How was the data validated?

The generator writes an expected defect manifest. A separate Python validator recalculates source counts. PostgreSQL repeats 18 checks before cleaning, reconciles all raw and clean row counts, and then runs ten zero-tolerance model tests after building the star schema.

## What was the strongest finding?

The stockout association is operationally clear: stockout-linked orders have a 96.70% late-delivery rate versus 36.98% when stock is available, with longer handling and delivery delays. It supports targeted replenishment analysis, while remaining an association rather than proof of causation.

## What would change in production?

The pipeline would use controlled ingestion, incremental loads, orchestration, access controls, secrets management, slowly changing dimensions where needed, formal data contracts, alerting, and monitored tests. Synthetic rules would be replaced by agreed definitions with business owners.

## Why is the project relevant to German analyst roles?

It demonstrates SQL, PostgreSQL, data validation, KPI governance, dimensional modelling, Power BI planning, inventory and logistics reasoning, root-cause analysis, Git history, and factual documentation—skills commonly transferable across BI, reporting, operations, and supply-chain roles.
