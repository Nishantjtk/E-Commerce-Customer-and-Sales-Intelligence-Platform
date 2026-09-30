SELECT category_name, SUM(line_revenue) AS revenue, COUNT(DISTINCT order_id) AS orders,
       RANK() OVER (ORDER BY SUM(line_revenue) DESC) AS revenue_rank
FROM analytics.order_line WHERE order_status = 'delivered' GROUP BY category_name ORDER BY revenue DESC;
