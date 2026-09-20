# Source data and scenario design

## Scenario

The synthetic company operates six fulfilment centres in Germany and serves customers across Germany and neighbouring European markets. Management needs one operational view of demand, fulfilment, carrier performance, stock availability, and exceptions.

All company, customer, warehouse, and carrier names are fictional. The generated performance patterns do not describe real organisations.

## Analysis period

- First source date: 2025-09-01
- Last source date: 2026-08-31
- Reporting date: 2026-09-01
- Currency: EUR
- Unique orders: 30,000 before intentional raw-file duplicates

Using a fixed reporting date makes backlog ageing and SLA calculations reproducible.

## Business flow

```text
Customer places order
        │
        ├── product demand is assigned to a warehouse
        │
        ├── inventory is consumed or a shortage is recorded
        │
        └── non-cancelled order may create a shipment
                              │
                              ├── carrier transports it
                              └── delivery is on time, late, or still open
```

## Source-table grain

Grain means exactly what one row represents.

| Table | Grain | Expected clean volume |
|---|---|---:|
| `products` | One sellable product | 120 |
| `warehouses` | One fulfilment centre | 6 |
| `carriers` | One carrier/service record | 7 |
| `customers` | One synthetic customer | 4,000 |
| `orders` | One order containing one product | 30,000 |
| `shipments` | One shipment for one order | Approximately 27,000–29,000 |
| `inventory` | One product at one warehouse on one calendar date | 262,800 |

The order source intentionally uses one product per order. A production retailer would commonly separate order headers and order lines, but that would add an eighth source table and unnecessary complexity for this beginner-to-intermediate portfolio case. The modelling decision is documented so the grain remains defensible in an interview.

## Relationships

```text
customers  1 ───< orders >─── 1 products
                    │
                    ├──────── 1 warehouses
                    │
                    └── 0..1 shipments >─── 1 carriers

products   1 ───< inventory >─── 1 warehouses
```

An order may have no shipment when it is cancelled or still waiting in backlog. Inventory uses a composite business key of snapshot date, warehouse, and product.

## Realistic patterns built into the clean scenario

- Weekday demand is higher than weekend demand.
- November and December have seasonal peaks.
- Product popularity and customer order quantities are uneven.
- Warehouse pressure and stock availability influence handling delays.
- Carrier service levels influence transit time and cost.
- Winter weather, inventory shortage, warehouse capacity, address, damage, system, carrier, and customer-request exceptions occur at controlled rates.
- Recent orders are more likely to be processing, packed, or in transit.
- A small number of older orders remain open, creating meaningful backlog-ageing analysis.

## Controlled raw-data imperfections

The generator injects a limited, deterministic set of defects after creating the coherent scenario:

- exact duplicate rows;
- missing customer, product, warehouse, or carrier identifiers;
- an unmapped warehouse code;
- negative order quantities and inventory balances;
- promised dates before order dates;
- delivery dates before shipment dates;
- inconsistent category and status labels;
- orphan shipment order references;
- inventory balance mismatches.

The file `data/quality_manifest.json` records the intended counts. The validator independently recalculates them. SQL then detects the same issues before cleaning.
