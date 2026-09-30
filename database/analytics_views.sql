\set ON_ERROR_STOP on
\i database/schema.sql

CREATE OR REPLACE VIEW analytics.order_financials AS
WITH item_totals AS (
  SELECT order_id, SUM(price) AS item_revenue, SUM(freight_value) AS freight_revenue,
         SUM(price + freight_value) AS gross_merchandise_value, COUNT(*) AS item_count
  FROM raw.order_items GROUP BY order_id
), payment_totals AS (
  SELECT order_id, SUM(payment_value) AS payment_value, MAX(payment_installments) AS max_installments
  FROM raw.order_payments GROUP BY order_id
), review_summary AS (
  SELECT order_id, AVG(review_score)::numeric(5,2) AS avg_review_score, COUNT(*) AS review_count
  FROM raw.order_reviews GROUP BY order_id
)
SELECT o.order_id, c.customer_unique_id, c.customer_city, c.customer_state,
       o.order_status, o.order_purchase_timestamp, o.order_approved_at,
       o.order_delivered_carrier_date, o.order_delivered_customer_date,
       o.order_estimated_delivery_date, i.item_revenue, i.freight_revenue,
       i.gross_merchandise_value, i.item_count, p.payment_value, p.max_installments,
       r.avg_review_score, r.review_count,
       CASE WHEN o.order_delivered_customer_date IS NOT NULL
            THEN EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400.0 END AS delivery_days,
       CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END AS is_late_delivery
FROM raw.orders o
JOIN raw.customers c ON c.customer_id = o.customer_id
LEFT JOIN item_totals i ON i.order_id = o.order_id
LEFT JOIN payment_totals p ON p.order_id = o.order_id
LEFT JOIN review_summary r ON r.order_id = o.order_id;

CREATE OR REPLACE VIEW analytics.order_line AS
SELECT oi.order_id, oi.order_item_id, o.order_purchase_timestamp, o.order_status,
       c.customer_unique_id, c.customer_state, s.seller_id, s.seller_state,
       oi.product_id, COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') AS category_name,
       oi.price, oi.freight_value, oi.price + oi.freight_value AS line_revenue
FROM raw.order_items oi
JOIN raw.orders o ON o.order_id = oi.order_id
JOIN raw.customers c ON c.customer_id = o.customer_id
JOIN raw.sellers s ON s.seller_id = oi.seller_id
LEFT JOIN raw.products p ON p.product_id = oi.product_id
LEFT JOIN raw.category_translation t ON t.product_category_name = p.product_category_name;

CREATE OR REPLACE VIEW analytics.customer_rfm AS
WITH reference_date AS (
  SELECT MAX(order_purchase_timestamp)::date + 1 AS as_of_date FROM raw.orders
), customer_orders AS (
  SELECT c.customer_unique_id, MAX(o.order_purchase_timestamp)::date AS last_purchase_date,
         COUNT(DISTINCT o.order_id) FILTER (WHERE o.order_status = 'delivered') AS frequency,
         COALESCE(SUM(f.item_revenue) FILTER (WHERE o.order_status = 'delivered'), 0) AS monetary
  FROM raw.customers c JOIN raw.orders o ON o.customer_id = c.customer_id
  LEFT JOIN analytics.order_financials f ON f.order_id = o.order_id
  GROUP BY c.customer_unique_id
), scored AS (
  SELECT co.*, (r.as_of_date - co.last_purchase_date) AS recency_days,
         6 - NTILE(5) OVER (ORDER BY (r.as_of_date - co.last_purchase_date)) AS recency_score,
         NTILE(5) OVER (ORDER BY co.frequency) AS frequency_score,
         NTILE(5) OVER (ORDER BY co.monetary) AS monetary_score
  FROM customer_orders co CROSS JOIN reference_date r
)
SELECT *, CONCAT(recency_score, frequency_score, monetary_score) AS rfm_score,
       CASE WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions / VIP Customers'
            WHEN recency_score >= 3 AND frequency_score >= 3 THEN 'Loyal Customers'
            WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Customers'
            WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At-Risk Customers'
            WHEN recency_score = 1 THEN 'Lost Customers'
            ELSE 'Regular Customers' END AS customer_segment
FROM scored;

CREATE OR REPLACE VIEW analytics.cohort_retention AS
WITH purchases AS (
  SELECT c.customer_unique_id, date_trunc('month', o.order_purchase_timestamp)::date AS purchase_month
  FROM raw.orders o JOIN raw.customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered'
), cohorts AS (
  SELECT customer_unique_id, MIN(purchase_month) AS cohort_month FROM purchases GROUP BY customer_unique_id
)
SELECT c.cohort_month, p.purchase_month,
       ((EXTRACT(YEAR FROM p.purchase_month) - EXTRACT(YEAR FROM c.cohort_month)) * 12
        + EXTRACT(MONTH FROM p.purchase_month) - EXTRACT(MONTH FROM c.cohort_month))::int AS cohort_index,
       COUNT(DISTINCT p.customer_unique_id) AS retained_customers
FROM purchases p JOIN cohorts c USING (customer_unique_id)
GROUP BY c.cohort_month, p.purchase_month;

CREATE OR REPLACE VIEW analytics.delivery_experience AS
SELECT f.*, CASE WHEN f.delivery_days IS NULL THEN 'Not delivered'
                 WHEN f.is_late_delivery = 1 THEN 'Late'
                 ELSE 'On time / early' END AS delivery_status
FROM analytics.order_financials f;

CREATE OR REPLACE VIEW analytics.category_experience AS
WITH category_orders AS (
  SELECT DISTINCT category_name, order_id
  FROM analytics.order_line
  WHERE order_status = 'delivered'
), category_sales AS (
  SELECT category_name, COUNT(DISTINCT order_id) AS delivered_orders,
         SUM(price) AS item_revenue, SUM(freight_value) AS freight_revenue,
         SUM(line_revenue) AS gross_merchandise_value
  FROM analytics.order_line
  WHERE order_status = 'delivered'
  GROUP BY category_name
), category_delivery AS (
  SELECT co.category_name, AVG(d.delivery_days) AS avg_delivery_days,
         AVG(d.is_late_delivery) AS late_delivery_rate,
         AVG(d.avg_review_score) AS avg_review_score
  FROM category_orders co
  JOIN analytics.delivery_experience d USING(order_id)
  GROUP BY co.category_name
)
SELECT s.category_name, s.delivered_orders, s.item_revenue AS revenue,
       d.avg_delivery_days, d.late_delivery_rate, d.avg_review_score,
       s.freight_revenue, s.gross_merchandise_value
FROM category_sales s
LEFT JOIN category_delivery d USING(category_name);

CREATE OR REPLACE VIEW analytics.payment_detail AS
SELECT p.order_id, p.payment_sequential, p.payment_type, p.payment_installments,
       p.payment_value, f.order_purchase_timestamp, f.order_status,
       f.customer_unique_id, f.customer_state, f.item_revenue,
       f.gross_merchandise_value
FROM raw.order_payments p
JOIN analytics.order_financials f USING(order_id);

CREATE OR REPLACE VIEW analytics.review_detail AS
SELECT r.review_row_id, r.review_id, r.order_id, r.review_score,
       r.review_creation_date, r.review_answer_timestamp,
       f.order_purchase_timestamp, f.order_status, f.customer_unique_id,
       f.customer_state, f.delivery_days, f.is_late_delivery,
       CASE WHEN f.delivery_days IS NULL THEN 'Not delivered'
            WHEN f.is_late_delivery = 1 THEN 'Late'
            ELSE 'On time / early' END AS delivery_status
FROM raw.order_reviews r
JOIN analytics.order_financials f USING(order_id);

CREATE OR REPLACE VIEW analytics.seller_experience AS
WITH seller_orders AS (
  SELECT DISTINCT seller_id, seller_state, order_id
  FROM analytics.order_line
  WHERE order_status = 'delivered'
), seller_sales AS (
  SELECT seller_id, seller_state, COUNT(DISTINCT order_id) AS delivered_orders,
         SUM(price) AS item_revenue, SUM(freight_value) AS freight_revenue
  FROM analytics.order_line
  WHERE order_status = 'delivered'
  GROUP BY seller_id, seller_state
), seller_delivery AS (
  SELECT so.seller_id, AVG(d.delivery_days) AS avg_delivery_days,
         AVG(d.is_late_delivery) AS late_delivery_rate,
         AVG(d.avg_review_score) AS avg_review_score
  FROM seller_orders so JOIN analytics.delivery_experience d USING(order_id)
  GROUP BY so.seller_id
)
SELECT s.seller_id, s.seller_state, s.delivered_orders, s.item_revenue,
       s.freight_revenue, s.item_revenue + s.freight_revenue AS gross_merchandise_value,
       d.avg_delivery_days, d.late_delivery_rate, d.avg_review_score
FROM seller_sales s LEFT JOIN seller_delivery d USING(seller_id);
