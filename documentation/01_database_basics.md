# Database basics

## What we are building

Imagine seven connected spreadsheets describing one fulfilment business. PostgreSQL will store those datasets as related tables. SQL will let us ask questions across them, such as: “Which warehouse has the highest late-delivery rate, and which exception reasons explain it?”

## Database

A **database** is an organised container for related data. Our project database will eventually contain raw source tables, cleaned tables, and analytics-ready tables.

Analogy: a database is a well-managed filing cabinet, not one individual sheet of paper.

## Table

A **table** stores one type of subject in a grid of rows and columns. Examples are `orders`, `products`, and `warehouses`.

Keeping different subjects in separate tables reduces repeated information and makes updates safer.

## Row

A **row** is one record. In an `orders` table, one row represents one order line in our planned source design.

Example:

| order_id | product_id | order_quantity |
|---|---|---:|
| ORD-000001 | PRD-0042 | 3 |

That row says order `ORD-000001` contains three units of product `PRD-0042`.

## Column

A **column** is one attribute that every row can hold. `order_date`, `warehouse_id`, and `order_quantity` are columns.

Each column should have a clear meaning and an appropriate data type.

## Data type

A **data type** tells PostgreSQL what kind of value a column accepts. Common examples are:

- `date` for calendar dates
- `integer` for whole-number quantities
- `numeric` for money or decimal values
- `text` for names, labels, and identifiers
- `boolean` for true/false values

Correct types prevent invalid operations, such as adding a customer name to a shipping cost.

## Primary key

A **primary key** uniquely identifies each row in a table. `product_id` can be the primary key of `products` because each product should appear once.

Primary keys must be unique and cannot be missing.

## Foreign key

A **foreign key** is a column that points to a primary key in another table. `orders.product_id` points to `products.product_id`.

This connection lets us store the product description once in `products` while every order refers to it by ID.

## Relationship

A **relationship** describes how tables connect. One product can appear on many orders, so `products` to `orders` is a one-to-many relationship.

```text
products (one) ─────< orders (many)
```

## Schema

In PostgreSQL, a **schema** is a named area inside a database used to organise tables. Later we plan to use:

- `raw` for imported source-like data
- `clean` for validated and standardised data
- `analytics` for star-schema facts, dimensions, and reporting views

This separation makes the transformation path easy to audit.

## Planned connected source tables

| Table | One row represents | Main identifier |
|---|---|---|
| `orders` | One order line | `order_id` in the initial brief; grain will be confirmed in Phase 2 |
| `shipments` | One shipment event for an order | `shipment_id` |
| `inventory` | One product at one warehouse on one snapshot date | Composite of date, warehouse, and product |
| `products` | One sellable product | `product_id` |
| `warehouses` | One fulfilment centre | `warehouse_id` |
| `carriers` | One delivery provider/service record | `carrier_id` |
| `customers` | One customer | `customer_id` |

The “one row represents” definition is called the **grain**. We will finalise it before generating data because unclear grain causes double counting later.
