# Project roadmap

## Phase 1 — Local environment and Git foundation

Learn the basic vocabulary, verify the Mac tools, create the project structure, initialise Git, and make the first commit.

**Completion gate:** PostgreSQL is reachable and the repository has a clean initial commit.

## Phase 2 — Business process and source-data design

Define how an order moves from placement to shipment and delivery. Agree the grain, keys, relationships, date range, volumes, business rules, and controlled data imperfections for each source table.

**Completion gate:** A reviewed data dictionary and relationship diagram exist before any rows are generated.

## Phase 3 — Reproducible synthetic dataset

Generate approximately 30,000 orders plus related shipments and daily inventory snapshots across 12 months. Validate row counts, key uniqueness, referential integrity, date ranges, and the intended dirty-data cases.

**Completion gate:** Every CSV passes automated structural checks and has a documented purpose.

## Phase 4 — PostgreSQL raw layer

Create the project database and schemas, define raw tables with appropriate data types, import the CSV files, and reconcile database counts to source counts.

**Completion gate:** Raw data is loaded without silently changing source values.

## Phase 5 — Data quality and cleaning

Write SQL tests for duplicates, missing IDs, invalid quantities, inconsistent labels, broken mappings, and impossible dates. Build cleaned tables with explicit, auditable rules.

**Completion gate:** Every intentional defect is detected, classified, and either corrected, mapped, quarantined, or retained with a reason.

## Phase 6 — Business analysis and KPIs

Learn SQL through real questions covering orders, revenue, backlog, delivery performance, exceptions, carriers, warehouses, and inventory risk.

**Completion gate:** KPI definitions, query results, and validation logic agree.

## Phase 7 — Dimensional model

Learn grain, facts, dimensions, surrogate keys, and one-to-many relationships. Build and test a star schema for analytics.

**Completion gate:** Fact-table row counts and dimension relationships are reconciled; no unintended many-to-many joins remain.

## Phase 8 — Power BI plan and DAX

Only after Phase 7, prepare the Mac-compatible Power BI workflow, semantic-model relationships, concise DAX measures, and four report pages.

**Completion gate:** Measures reconcile to PostgreSQL and visuals answer defined business questions.

## Phase 9 — Findings and portfolio hand-off

Document evidence-based observations, likely causes, implications, and recommendations. Finish screenshots, README, CV bullets, and interview questions without inventing real-world impact.

**Completion gate:** The repository can be reproduced and every public claim is defensible.
