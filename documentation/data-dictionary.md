# Data dictionary

## `products.csv`

| Column | Meaning | Planned PostgreSQL type |
|---|---|---|
| `product_id` | Stable synthetic SKU identifier | `text` |
| `product_name` | Fictional product description | `text` |
| `product_category` | Product reporting category | `text` |
| `unit_cost_eur` | Synthetic acquisition cost per unit | `numeric(10,2)` |
| `unit_price_eur` | Synthetic list price per unit | `numeric(10,2)` |
| `weight_kg` | Shipment weight per unit | `numeric(8,2)` |
| `supplier_lead_time_days` | Typical replenishment lead time | `integer` |

## `warehouses.csv`

| Column | Meaning | Planned PostgreSQL type |
|---|---|---|
| `warehouse_id` | Stable fulfilment-centre identifier | `text` |
| `warehouse_name` | Fictional warehouse name | `text` |
| `city` | German warehouse city | `text` |
| `country` | ISO country code | `text` |
| `storage_capacity_units` | Approximate unit-storage capacity | `integer` |
| `daily_order_capacity` | Sustainable orders processed per day | `integer` |

## `carriers.csv`

| Column | Meaning | Planned PostgreSQL type |
|---|---|---|
| `carrier_id` | Stable carrier identifier | `text` |
| `carrier_name` | Fictional carrier name | `text` |
| `service_level` | Economy, Standard, or Express | `text` |
| `base_transit_days` | Typical domestic transit time | `integer` |

## `customers.csv`

| Column | Meaning | Planned PostgreSQL type |
|---|---|---|
| `customer_id` | Stable synthetic customer identifier | `text` |
| `customer_name` | Non-personal synthetic label | `text` |
| `customer_segment` | Consumer, Small Business, Mid-Market, or Enterprise | `text` |
| `city` | Customer city | `text` |
| `country` | ISO country code | `text` |
| `signup_date` | Synthetic customer start date | `date` |

## `orders.csv`

| Column | Meaning | Planned PostgreSQL type |
|---|---|---|
| `order_id` | Stable order identifier | `text` |
| `customer_id` | Customer reference | `text` |
| `product_id` | Product reference | `text` |
| `warehouse_id` | Fulfilling warehouse reference | `text` |
| `order_date` | Date the order was placed | `date` |
| `promised_delivery_date` | Customer-facing delivery commitment | `date` |
| `order_status` | Current order lifecycle status | `text` |
| `order_quantity` | Units ordered | `integer` |
| `unit_price_eur` | Selling price per unit before discount | `numeric(10,2)` |
| `discount_pct` | Discount expressed as a decimal fraction | `numeric(6,4)` |
| `order_value_eur` | Quantity × price × (1 − discount) | `numeric(12,2)` |
| `sales_channel` | Online Store, Marketplace, EDI, or Sales Desk | `text` |

## `shipments.csv`

| Column | Meaning | Planned PostgreSQL type |
|---|---|---|
| `shipment_id` | Stable shipment identifier | `text` |
| `order_id` | Related order reference | `text` |
| `carrier_id` | Related carrier reference | `text` |
| `ship_date` | Date handed to the carrier | `date` |
| `actual_delivery_date` | Delivery date; blank while undelivered | `date` |
| `shipment_status` | Delivered or In Transit | `text` |
| `shipping_cost_eur` | Synthetic freight cost | `numeric(10,2)` |
| `exception_reason` | Operational issue; blank when none recorded | `text` |

## `inventory.csv`

| Column | Meaning | Planned PostgreSQL type |
|---|---|---|
| `inventory_date` | Daily snapshot date | `date` |
| `warehouse_id` | Warehouse reference | `text` |
| `product_id` | Product reference | `text` |
| `opening_stock` | Units at the start of the day | `integer` |
| `received_quantity` | Units received during the day | `integer` |
| `shipped_quantity` | Units fulfilled from available stock | `integer` |
| `closing_stock` | Opening + received − shipped | `integer` |
| `reorder_level` | Stock threshold that triggers replenishment attention | `integer` |
