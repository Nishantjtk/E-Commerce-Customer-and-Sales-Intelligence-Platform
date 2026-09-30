-- Source-quality exception counts. Repeated unique customers are valid repeat-purchase behaviour.
SELECT 'orders_without_items' AS check_name, COUNT(*) AS exceptions FROM raw.orders o LEFT JOIN raw.order_items i USING(order_id) WHERE i.order_id IS NULL
UNION ALL SELECT 'delivered_without_delivery_date', COUNT(*) FROM raw.orders WHERE order_status = 'delivered' AND order_delivered_customer_date IS NULL
UNION ALL SELECT 'negative_delivery_duration', COUNT(*) FROM raw.orders WHERE order_delivered_customer_date < order_purchase_timestamp
UNION ALL SELECT 'repeat_unique_customers', COUNT(*) FROM (SELECT customer_unique_id FROM raw.customers GROUP BY customer_unique_id HAVING COUNT(*) > 1) x;
