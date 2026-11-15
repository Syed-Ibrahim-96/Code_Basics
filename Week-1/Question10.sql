-- Question 10

-- Turn on SET STATISTICS IO, TIME ON and "Include Actual Execution Plan", run it, then make it fast:
-- explain what the plan is doing, rewrite the query, and add an index that helps. 
-- Required output: the rewritten query, the CREATE INDEX statement(s), 
-- and a short note giving the logical reads before versus after and why the plan changed

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

--SELECT o.customer_id, COUNT(*) AS orders_2024,
--           (SELECT SUM(oi.line_amount)
--              FROM fact_order_items oi
--              JOIN fact_orders o2 ON o2.order_id = oi.order_id
--             WHERE o2.customer_id = o.customer_id) AS lifetime_value
--    FROM fact_orders o
--    WHERE YEAR(o.order_date) = 2024
--    GROUP BY o.customer_id;



DROP INDEX IF EXISTS IX_fact_order_items_order_id
ON dbo.fact_order_items;

CREATE NONCLUSTERED INDEX IX_fact_order_items_order_id
ON dbo.fact_order_items (order_id)
INCLUDE (line_amount);

DROP INDEX IF EXISTS IX_fact_orders_order_date
ON dbo.fact_orders;


CREATE NONCLUSTERED INDEX IX_fact_orders_order_date 
ON dbo.fact_orders (order_date) 
INCLUDE (customer_id);



DROP TABLE IF EXISTS #CustomerOrders2024;

-- Step 1: Calculate 2024 orders once
SELECT
    customer_id,
    COUNT(*) AS orders_2024
INTO #CustomerOrders2024
FROM dbo.fact_orders
WHERE order_date >= '2024-01-01'
  AND order_date <  '2025-01-01'
GROUP BY customer_id;


-- Step 2: Calculate lifetime value
SELECT
    c.customer_id,
    c.orders_2024,
    SUM(oi.line_amount) AS lifetime_value
FROM #CustomerOrders2024 c
LEFT JOIN dbo.fact_orders o
    ON o.customer_id = c.customer_id
LEFT JOIN dbo.fact_order_items oi
    ON oi.order_id = o.order_id
GROUP BY
    c.customer_id,
    c.orders_2024;


-- Step 3: Cleanup
DROP TABLE #CustomerOrders2024;

-- RESULT WRITE UP

-- Optimized the customer order report by replacing the correlated subquery with a temporary-table-based aggregation, 
-- allowing the 2024 customer results to be calculated once and reused. Introduced a covering index on `fact_order_items` 
-- to improve order-level data retrieval, reducing logical reads on that table from 267 to 186. Further refined the approach 
-- to minimize repeated access to `fact_orders` and improve overall query efficiency. Final performance gains will be validated 
-- using execution statistics.

