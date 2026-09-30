-- Dataset volume and order-status distribution
SELECT 'customers' AS entity, COUNT(*) AS row_count FROM raw.customers UNION ALL
SELECT 'orders', COUNT(*) FROM raw.orders UNION ALL SELECT 'order_items', COUNT(*) FROM raw.order_items
UNION ALL SELECT 'payments', COUNT(*) FROM raw.order_payments UNION ALL SELECT 'reviews', COUNT(*) FROM raw.order_reviews;
SELECT order_status, COUNT(*) AS orders FROM raw.orders GROUP BY order_status ORDER BY orders DESC;
