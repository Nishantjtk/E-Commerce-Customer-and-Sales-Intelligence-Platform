WITH monthly AS (
 SELECT date_trunc('month', order_purchase_timestamp)::date AS month, SUM(item_revenue) AS revenue, COUNT(*) AS orders
 FROM analytics.order_financials WHERE order_status = 'delivered' GROUP BY 1
)
SELECT month, revenue, orders, revenue - LAG(revenue) OVER (ORDER BY month) AS revenue_mom_change,
       ROUND(100 * (revenue / NULLIF(LAG(revenue) OVER (ORDER BY month),0) - 1),2) AS revenue_mom_pct
FROM monthly ORDER BY month;
