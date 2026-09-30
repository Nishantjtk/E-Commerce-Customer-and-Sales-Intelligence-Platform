SELECT customer_segment, COUNT(*) AS customers, SUM(monetary) AS revenue, AVG(frequency) AS avg_delivered_orders
FROM analytics.customer_rfm GROUP BY customer_segment ORDER BY revenue DESC;
