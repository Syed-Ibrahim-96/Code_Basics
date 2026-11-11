-- Question 4

--Finance wants the revenue trend with momentum. 
-- Produce monthly completed revenue with a cumulative running total and the month-over-month % change. 
--Required output: order_month (YYYY-MM), monthly_revenue, running_total, mom_pct_change.

WITH monthly_revenue AS
(
    SELECT
        FORMAT(a.order_date, 'yyyy-MM') AS order_month,
        SUM(a.order_total) AS monthly_revenue
    FROM fact_orders AS a
    WHERE a.order_status = 'Completed'
    GROUP BY FORMAT(a.order_date, 'yyyy-MM')
),
revenue_analysis AS
(
    SELECT
        order_month,
        monthly_revenue,

        -- Running Total
        SUM(monthly_revenue) OVER (
            ORDER BY order_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total,

        -- Previous Month Revenue
        LAG(monthly_revenue) OVER (
            ORDER BY order_month
        ) AS previous_month_revenue

    FROM monthly_revenue
)

SELECT
    order_month,
    monthly_revenue,
    running_total,

    -- Month-over-Month % Change
    FORMAT(
        (monthly_revenue - previous_month_revenue) * 1.0
        / NULLIF(previous_month_revenue, 0),
        'P2'
    ) AS mom_pct_change

FROM revenue_analysis
ORDER BY order_month;


-- RESULT WRITE UP

-- Analyzed monthly completed revenue to track cumulative revenue and month-over-month percentage changes. 
-- This provides the Finance team with visibility into revenue trends and growth momentum, helping identify increases or declines in monthly performance.