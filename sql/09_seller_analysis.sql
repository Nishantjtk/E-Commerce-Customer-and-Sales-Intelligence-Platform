SELECT seller_id, seller_state, COUNT(DISTINCT order_id) AS orders, SUM(line_revenue) AS revenue,
       RANK() OVER (ORDER BY SUM(line_revenue) DESC) AS seller_revenue_rank
FROM analytics.order_line WHERE order_status = 'delivered' GROUP BY seller_id, seller_state ORDER BY revenue DESC;
