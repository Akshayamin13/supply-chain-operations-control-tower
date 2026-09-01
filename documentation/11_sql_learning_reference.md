# SQL learning reference

Every construct is used to answer an operational question in `sql/12_sql_learning_queries.sql` rather than as an isolated classroom exercise.

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

