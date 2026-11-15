-- Question 5

--The CRM team wants to size up the customer base by value. Split customers into four quartiles by lifetime completed spend, 
-- and for each quartile report how many customers fall in it and their average spend. 
-- Required output: spend_quartile, customer_count, avg_lifetime_spend.

WITH total_orders AS
(
SELECT customer_id,
	   CAST(SUM(order_total) AS DECIMAL(10,2)) AS total_spend
FROM fact_orders
WHERE order_status = 'Completed'
GROUP BY customer_id
),

four_quartiles AS
(
SELECT customer_id,total_spend,
NTILE(4) OVER(ORDER BY total_spend DESC) AS spend_quartile
FROM total_orders
)

SELECT spend_quartile, COUNT(*) AS customer_count,
	   CAST(AVG(total_spend) AS DECIMAL(10,2)) AS avg_lifetime_spend
FROM four_quartiles
GROUP BY spend_quartile
ORDER BY spend_quartile
;


-- RESULT WRITE UP

-- Segmented customers into four quartiles based on their lifetime completed spend, highlighting the customer distribution and average spending across each segment. 
-- This analysis helps identify high-value customer segments and supports targeted marketing, customer engagement, and retention strategies.