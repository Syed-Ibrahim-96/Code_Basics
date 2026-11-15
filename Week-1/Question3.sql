-- Question 3

--  Merchandising wants the stars of each category. For every category, return the
-- top 3 products by completed revenue. 
-- Required output: category_name, product_name, total_revenue, revenue_rank.

WITH total_revenue AS
(
SELECT
    a.category_name, b.product_name,
    SUM(c.line_amount) AS total_revenue
    FROM dim_category AS a
    INNER JOIN dim_product AS b
    ON a.category_id = b.category_id
    INNER JOIN fact_order_items AS c
    ON b.product_id = c.product_id
    INNER JOIN fact_orders AS d
    ON c.order_id = d.order_id
    WHERE d.order_status = 'Completed'
    GROUP BY a.category_name, b.product_name
),
revenue_rank AS
(
SELECT a.category_name, a.product_name, a.total_revenue,
DENSE_RANK() OVER(PARTITION BY category_name ORDER BY total_revenue DESC) AS revenue_rank
FROM total_revenue AS a
)

SELECT * FROM revenue_rank
WHERE revenue_rank <=3
ORDER BY category_name,revenue_rank;

-- RESULT WRITE UP

-- Identified the top-performing products across each category based on completed order revenue. Calculated the total revenue for each product 
-- and ranked them within their respective categories using DENSE_RANK().

-- The results highlight the top 3 revenue-generating positions in each category, helping the merchandising team understand which products are driving sales 
-- and make informed decisions around product assortment and inventory planning.