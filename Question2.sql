-- Question 2

-- Marketing wants to re-engage people who registered but never bought. List the
-- customers who have never placed an order. Required output: customer_id, customer_name, signup_date.


SELECT
    a.customer_id,
    a.customer_name,
    a.signup_date
FROM dim_customer AS a
WHERE NOT EXISTS (
    SELECT 1
    FROM fact_orders AS b
    WHERE a.customer_id = b.customer_id
);



-- RESULT WRITE UP

-- Checked the customer records to identify those who registered but never placed an order. However, the query returned no records, 
-- indicating that every customer in the current dataset has at least one associated order.

-- As a result, no customers were identified for the marketing team's re-engagement campaign.