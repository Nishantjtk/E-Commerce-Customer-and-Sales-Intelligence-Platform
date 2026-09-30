WITH category_month AS (
 SELECT date_trunc('month', order_purchase_timestamp)::date AS month, category_name, SUM(line_revenue) AS revenue
 FROM analytics.order_line WHERE order_status = 'delivered' GROUP BY 1,2
)
SELECT month, category_name, revenue,
       SUM(revenue) OVER (PARTITION BY category_name ORDER BY month) AS running_revenue,
       AVG(revenue) OVER (PARTITION BY category_name ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_month_moving_avg
FROM category_month ORDER BY category_name, month;
