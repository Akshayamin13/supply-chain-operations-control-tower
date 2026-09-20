# SQL foundations

## What we are building

Imagine seven connected spreadsheets describing one fulfilment business. PostgreSQL will store those datasets as related tables. SQL will let us ask questions across them, such as: “Which warehouse has the highest late-delivery rate, and which exception reasons explain it?”

## Database

A **database** is an organised container for related data. Our project database contains raw source tables, cleaned tables, and analytics-ready tables.

Analogy: a database is a well-managed filing cabinet, not one individual sheet of paper.

## Table

A **table** stores one type of subject in a grid of rows and columns. Examples are `orders`, `products`, and `warehouses`.

Keeping different subjects in separate tables reduces repeated information and makes updates safer.

## Row

A **row** is one record. In an `orders` table, one row represents one order containing one product.

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

In PostgreSQL, a **schema** is a named area inside a database used to organise tables. This project uses:

- `raw` for imported source-like data
- `clean` for validated and standardised data
- `analytics` for star-schema facts, dimensions, and reporting views

This separation makes the transformation path easy to audit.

## Connected source tables

| Table | One row represents | Main identifier |
|---|---|---|
| `orders` | One order containing one product | `order_id` |
| `shipments` | One shipment event for an order | `shipment_id` |
| `inventory` | One product at one warehouse on one snapshot date | Composite of date, warehouse, and product |
| `products` | One sellable product | `product_id` |
| `warehouses` | One fulfilment centre | `warehouse_id` |
| `carriers` | One delivery provider/service record | `carrier_id` |
| `customers` | One customer | `customer_id` |

The “one row represents” definition is called the **grain**. This project declares each grain before aggregation because unclear grain causes double counting.

## SQL constructs in the finished project

Every construct is used to answer an operational question in [sql/12_sql_learning_queries.sql](../sql/12_sql_learning_queries.sql) rather than as an isolated classroom exercise.

| SQL concept | Plain-language purpose | Project use |
|---|---|---|
| `SELECT` | Chooses the columns to return | Select order, warehouse, value, and backlog age for high-risk orders. |
| `FROM` | Identifies the source table or view | Read from the cleaned and analytics layers. |
| `WHERE` | Filters rows before aggregation | Keep eligible orders or critical/high risks. |
| `ORDER BY` | Sorts the result | Put oldest or weakest performance first. |
| `LIMIT` | Returns only the first number of rows | Show the top 20 orders requiring attention. |
| `DISTINCT` | Removes repeated result values | List the standardised order statuses. |
| `CASE WHEN` | Applies conditional business labels | Classify warehouse volume bands and backlog buckets. |
| `GROUP BY` | Creates one result per category | Summarise by warehouse or month. |
| `HAVING` | Filters groups after aggregation | Keep warehouses with enough volume for comparison. |
| `COUNT` | Counts rows or events | Orders, shipments, exceptions, and backlog. |
| `SUM` | Adds numeric measures | Revenue, units, costs, and throughput. |
| `AVG` | Calculates a mean | Order value, delay, and lead time. |
| `MIN` / `MAX` | Finds the lowest/highest value | First and last operational dates or peak utilisation. |
| `INNER JOIN` | Keeps only matching rows | Combine valid orders with known warehouses. |
| `LEFT JOIN` | Keeps every row from the left table | Preserve unshipped orders for backlog analysis. |
| CTE (`WITH`) | Names an intermediate result | Calculate company averages or duplicate ranks clearly. |
| Subquery | Uses one query inside another | Compare each warehouse with the company KPI. |
| Date functions | Group or compare dates | Monthly trend and ageing calculations. |
| `NULL` | Represents unknown/not applicable | An undelivered shipment has no actual delivery date. |
| `COALESCE` | Replaces `NULL` for display or fallback | Label a missing shipment as `Not shipped`. |
| `ROW_NUMBER` | Numbers rows inside a group | Identify extra rows for the same order ID. |
| `RANK` | Assigns ordered positions with ties | Rank carriers overall and within service level. |
| `LAG` | Reads a previous ordered row | Compare this month's orders with last month. |
| `LEAD` | Reads a following ordered row | Show the next month's volume for context. |
| Window function | Calculates across related rows without collapsing them | Running total of orders while retaining each month. |

## Join lesson

An `INNER JOIN` between orders and shipments would remove every order that has not shipped. That is appropriate for shipment-only performance, but wrong for backlog. The fulfilment view therefore starts from orders and uses a `LEFT JOIN` to shipments.

## Grain lesson

Always confirm grain before aggregating. Summing order value after joining orders to daily inventory would repeat each order across many inventory rows. Separate fact tables and deliberate joins prevent this double counting.
