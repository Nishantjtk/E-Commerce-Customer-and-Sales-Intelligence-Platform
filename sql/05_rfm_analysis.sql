SELECT customer_unique_id, recency_days, frequency, monetary, rfm_score, customer_segment
FROM analytics.customer_rfm ORDER BY monetary DESC, frequency DESC;
