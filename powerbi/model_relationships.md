# Semantic-model relationships

## Full PostgreSQL star schema

Use this model when Power BI connects directly to PostgreSQL or when the full fact exports are loaded in a Windows/Desktop environment. Create one-to-many, single-direction relationships from dimensions to facts.

| One side | Key | Many side | Key | Active? |
|---|---|---|---|---|
| `DimDate` | `date_key` | `FactOrders` | `order_date_key` | Yes |
| `DimDate` | `date_key` | `FactOrders` | `promised_delivery_date_key` | No |
| `DimDate` | `date_key` | `FactShipments` | `ship_date_key` | Yes |
| `DimDate` | `date_key` | `FactShipments` | `promised_delivery_date_key` | No |
| `DimDate` | `date_key` | `FactShipments` | `actual_delivery_date_key` | No |
| `DimDate` | `date_key` | `FactInventory` | `inventory_date_key` | Yes |
| `DimProduct` | `product_key` | `FactOrders` | `product_key` | Yes |
| `DimProduct` | `product_key` | `FactShipments` | `product_key` | Yes |
| `DimProduct` | `product_key` | `FactInventory` | `product_key` | Yes |
| `DimCustomer` | `customer_key` | `FactOrders` | `customer_key` | Yes |
| `DimCustomer` | `customer_key` | `FactShipments` | `customer_key` | Yes |
| `DimWarehouse` | `warehouse_key` | `FactOrders` | `warehouse_key` | Yes |
| `DimWarehouse` | `warehouse_key` | `FactShipments` | `warehouse_key` | Yes |
| `DimWarehouse` | `warehouse_key` | `FactInventory` | `warehouse_key` | Yes |
| `DimCarrier` | `carrier_key` | `FactShipments` | `carrier_key` | Yes |

Use `measures.dax` with this model.

## Mac/browser workbook aggregate model

Use this model with `control_tower_powerbi_browser_source.xlsx`.

| One side | Key | Many side | Key |
|---|---|---|---|
| `DimDate` | `date_key` | `OrderSummary` | `order_month_key` |
| `DimDate` | `date_key` | `ShipmentSummary` | `ship_month_key` |
| `DimDate` | `date_key` | `InventorySummary` | `inventory_month_key` |
| `DimWarehouse` | `warehouse_key` | `OrderSummary` | `warehouse_key` |
| `DimWarehouse` | `warehouse_key` | `ShipmentSummary` | `warehouse_key` |
| `DimWarehouse` | `warehouse_key` | `InventorySummary` | `warehouse_key` |
| `DimCarrier` | `carrier_key` | `ShipmentSummary` | `carrier_key` |
| `DimProduct` | `product_key` | `InventorySummary` | `product_key` |

All are active, one-to-many, single-direction relationships. `OrderSummary` and `ShipmentSummary` carry product category as a degenerate reporting attribute; customer segment is also stored directly in `OrderSummary`. `ExecutiveKPIs` is a disconnected validation table and should not drive report visuals.

Use `measures_browser_aggregate.dax` with this model.

## General modelling rules

Do not relate fact or summary tables directly. Hide numeric keys from report view after relationships are created. Sort `DimDate[month_name]` by `month_number` and `DimDate[year_month]` by `month_start_date`.

