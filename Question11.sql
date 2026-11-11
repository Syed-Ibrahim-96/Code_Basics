-- Question 11

-- The retention team wants loyalty streaks. For each customer, find the longest run of consecutive calendar months in which 
-- they placed at least one completed order. 
-- Required output: customer_id, customer_name, longest_streak_months.

WITH Customer_Months AS
(
    SELECT DISTINCT
        customer_id,
        DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS order_month
    FROM fact_orders
    WHERE order_status = 'Completed'
),

Monthly_Sequence AS
(
    SELECT
        customer_id, order_month,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_month ) AS rn
    FROM Customer_Months
),

Streak_Groups AS
(
    SELECT
        customer_id, order_month,
        DATEADD(MONTH,-CAST(rn AS INT),order_month) AS streak_group
    FROM Monthly_Sequence
),

Customer_Streaks AS
(

    SELECT
        customer_id, streak_group,
        COUNT(*) AS streak_months
    FROM Streak_Groups
    GROUP BY
        customer_id, streak_group
)

SELECT
    a.customer_id, a.customer_name,
    COALESCE(MAX(b.streak_months), 0) AS longest_streak_months
FROM dim_customer AS a
LEFT JOIN Customer_Streaks AS b
    ON a.customer_id = b.customer_id
GROUP BY
    a.customer_id,
    a.customer_name
ORDER BY
    a.customer_id;

-- RESULT WRITE UP

-- Identified the longest streak of consecutive calendar months in which each customer placed at least one completed order. 
-- The analysis accounts for multiple orders within the same month and identifies uninterrupted monthly purchasing patterns.
-- This provides the retention team with valuable insights into customer loyalty, helping them recognize consistently engaged
-- customers and develop targeted retention strategies.

