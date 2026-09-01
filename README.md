# Supply Chain & Operations Control Tower

An analytics portfolio project that models fulfilment-centre operations across orders, shipments, inventory, products, warehouses, carriers, and customers.

> **Current status:** Phase 1 — local environment and repository setup complete. The dataset, SQL analysis, dimensional model, and dashboard have not been built yet.

## Business problem

Operations managers often receive separate files for orders, deliveries, warehouse activity, and stock. That makes it difficult to spot late orders, growing backlog, stockout risk, weak carrier performance, and recurring operational exceptions in one place.

This project will create a controlled analytics workflow that turns connected but imperfect operational data into trustworthy KPIs and a management-ready control tower.

## What this project will build

1. A reproducible synthetic dataset covering 12 months and approximately 30,000 orders.
2. Raw PostgreSQL tables that preserve the supplied data.
3. Documented data-quality checks and transparent cleaning rules.
4. Business KPI and root-cause analysis queries in SQL.
5. A star schema with order, shipment, and inventory fact tables plus reusable dimensions.
6. A Power BI semantic model and four-page dashboard plan after the SQL model is validated.
7. Evidence-based findings, recommendations, and interview preparation.

## Intended roles

- Operations Analyst
- Supply Chain Analyst
- Logistics Analyst
- BI / Reporting Analyst
- Inventory Analyst
- Operations Performance Analyst

## Tools

- PostgreSQL 16
- SQL
- Python (for reproducible synthetic-data generation)
- Git and GitHub
- Power BI later in the project, using a Mac-compatible workflow

## Repository structure

```text
.
├── data/
│   ├── raw/          # Generated source-like CSV files, preserved unchanged
│   ├── processed/    # Controlled exports created later
│   └── tmp/          # Disposable local working files; not versioned
├── documentation/    # Learning notes, data dictionary, architecture, decisions
├── powerbi/          # DAX and report design, intentionally deferred
├── screenshots/      # Final model and dashboard images
├── scripts/          # Reproducible data-generation and validation programs
└── sql/              # Numbered PostgreSQL scripts in execution order
```

## Delivery roadmap

The work is divided into gated phases so that each layer is understood and tested before the next begins. See [documentation/00_project_roadmap.md](documentation/00_project_roadmap.md).

## Data statement

All operational records in this repository will be synthetic. No real customer, employer, or commercially sensitive data will be used. Results will describe the simulated scenario only and will not claim real-world business impact.
