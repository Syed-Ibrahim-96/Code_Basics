-- Question 1

--Voltkart's commercial team wants a quick look at the biggest sales. Return the
--top 20 completed orders by value, with the customer and the sales rep behind each one. 
--Required output: order_id, order_date, customer_name, sales_rep_name, order_total.


SELECT TOP 20
a.order_id, a.order_date, b.customer_name, 
c.employee_name AS sales_rep_name, a.order_total

FROM fact_orders AS a
INNER JOIN dim_customer AS b
ON a.customer_id = b.customer_id
INNER JOIN dim_employee AS c
ON a.sales_rep_id = c.employee_id
WHERE order_status = 'Completed'
ORDER BY a.order_total DESC


-- RESULT WRITE UP

--Please find the list of the top 20 highest-value completed orders, along with the corresponding customer names and sales representatives.

--The results are sorted by order value in descending order, making it easier to identify the largest sales transactions and understand which customers and sales representatives contributed to them.

--This provides a quick overview of our highest-value completed orders for business review and sales performance tracking.