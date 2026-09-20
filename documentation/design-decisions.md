# Design decisions

## Why these views

The overview answers whether service is meeting expectations. Fulfilment separates warehouse and carrier performance. Inventory identifies the products exposed to repeated stockouts. Diagnostics brings the analysis back to an actionable order queue. Each page has a distinct operational question.

The project is a synthetic case study. Its scale and capacity values are chosen for a small reproducible scenario; they are not benchmarks for a real fulfilment operation.

## Local PostgreSQL before report design

The available machine is a 2019 Intel MacBook Air. PostgreSQL, Python and Git run locally, while Power BI Desktop requires a Windows environment. The decision was to complete and validate the SQL foundation before building the reporting layer.

The consequence is two reporting paths: a static web dashboard that is already published, and a workbook/DAX handoff for Power BI. The full SQL model is inspectable independently of either presentation layer.

## Separate facts instead of one wide table

Orders, shipments and inventory snapshots have different grains. A physical join between all three would multiply values. Three fact tables preserve those grains and share only the relevant dimensions. Carrier filters do not apply to inventory; Customer filters do not describe warehouse stock.

One product per order is a deliberate simplification. Split shipments, multi-line orders and returns would need additional modelling before using this structure in production.

## Compact browser data with declared limits

The Power BI workbook contains monthly summaries with additive counts and KPI numerators/denominators. Percentages must be recalculated from those components, not averaged across groups. Full transaction facts remain in PostgreSQL.

The web dashboard uses precomputed exports. A carrier selection shows that carrier's network-wide performance; it is not a warehouse-by-carrier intersection. Network benchmarks remain fixed. The interface and README describe those scopes so a filter does not imply detail the export cannot supply.

## Changes recorded during development

### Shipment events after the analysis date

An early generator could produce future shipment events inside a fixed historical snapshot. [Commit d3eeae5](https://github.com/Akshayamin13/supply-chain-operations-control-tower/commit/d3eeae54ffcbeff0cf21b0d01dfe1ceee737baaf) excludes shipments on or after the analysis date and leaves those orders Processing or On Hold. This makes the backlog state consistent with what could be known at the reporting cutoff.

### Tab styling after repository consolidation

Consolidation removed a shared stylesheet that defined the tab component's state variants. The browser consequently placed navigation beside the content, creating a large blank panel. [Commit b2a03e3](https://github.com/Akshayamin13/supply-chain-operations-control-tower/commit/b2a03e321e4380d01344e102f91b01191e979d10) restores the required variants. The published build was checked for layout, tabs and carrier/category filters.

## What the recommendations do not establish

Capacity exceptions and late delivery are associated in data generated from known rules. Their counts do not establish how many deliveries a capacity intervention would recover. Any proposed transfer volume needs daily receiving capacity, stock availability, delivery commitments and cost constraints, followed by a measured pilot.

Similarly, old backlog records need status verification before operational escalation. The fixed snapshot intentionally retains unresolved historic orders; their age is an analytical signal, not evidence that a real customer has waited that long.
