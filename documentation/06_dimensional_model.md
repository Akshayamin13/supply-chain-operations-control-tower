# Dimensional model

## Why a star schema?

Operational source tables are designed to record events. Analytics repeatedly groups those events by dates, products, customers, warehouses, and carriers. A star schema separates measurable events into fact tables and reusable descriptive context into dimension tables.

This produces clearer relationships, consistent filters, simpler DAX, and less repeated descriptive data than one giant joined table.

## Core concepts

- **Fact table:** stores measurable events at a declared grain.
- **Dimension table:** stores descriptive attributes used to filter and group facts.
- **Grain:** the exact meaning of one fact row.
- **Surrogate key:** an analytics-generated numeric key independent of the source-system ID.
- **One-to-many relationship:** one dimension row can describe many fact rows.
- **Conformed dimension:** one shared dimension filters more than one fact table consistently.

## Model

```text
                        DimDate
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   FactOrders        FactShipments       FactInventory
        │                  │                  │
        ├──── DimProduct ──┴──────────────────┤
        ├──── DimWarehouse ───────────────────┤
        ├──── DimCustomer ──┤
        └───────────────────┴──── DimCarrier
```

`DimCarrier` applies only to shipments. Other dimensions are shared where the business relationship exists.

## Fact-table grains

| Fact table | Grain | Rows |
|---|---|---:|
| `FactOrders` | One deduplicated order | 30,000 |
| `FactShipments` | One deduplicated shipment | 28,534 |
| `FactInventory` | One date × warehouse × product snapshot after deduplication | 262,800 |

## Dimension sizes

Each business dimension includes an explicit key `0` Unknown member.

| Dimension | Business members | Plus Unknown |
|---|---:|---:|
| `DimDate` | 371 calendar dates | 1 |
| `DimProduct` | 120 products | 1 |
| `DimCustomer` | 4,000 customers | 1 |
| `DimWarehouse` | 6 warehouses | 1 |
| `DimCarrier` | 7 carriers | 1 |

`DimDate` extends through 2026-09-06 because valid recent orders have future promised delivery dates, even though operational backlog is calculated as of 2026-09-01.

The generated browser workbook uses monthly reporting summaries for orders, shipments, and inventory so it can be imported reliably through the Mac/browser workflow. The authoritative PostgreSQL facts remain at full grain.

## Role-playing dates

The same date dimension supports several business dates:

- order date and promised delivery date in `FactOrders`;
- ship date, promised delivery date, and actual delivery date in `FactShipments`;
- inventory date in `FactInventory`.

Power BI should keep one active date relationship per fact and use inactive relationships or `USERELATIONSHIP` for alternate date views.

## Model tests

The SQL pipeline stops unless all of these pass:

- clean-to-fact row-count reconciliation;
- unique order and shipment grains;
- no unresolved dimensions on eligible operational records;
- eligible order-value reconciliation;
- complete date-dimension coverage.
