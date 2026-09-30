-- Run from the repository root with psql: psql ... -f database/data_loading.sql
-- The script intentionally avoids credentials; provide them through the environment or prompt.
\set ON_ERROR_STOP on

BEGIN;
TRUNCATE raw.order_reviews, raw.order_payments, raw.order_items, raw.orders,
         raw.geolocation, raw.category_translation, raw.products, raw.sellers,
         raw.customers RESTART IDENTITY;

\copy raw.customers FROM 'data/raw/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy raw.sellers FROM 'data/raw/olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy raw.products FROM 'data/raw/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy raw.category_translation FROM 'data/raw/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy raw.orders FROM 'data/raw/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy raw.order_items FROM 'data/raw/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy raw.order_payments FROM 'data/raw/olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy raw.order_reviews (review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp) FROM 'data/raw/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy raw.geolocation FROM 'data/raw/olist_geolocation_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');
COMMIT;

ANALYZE raw.customers;
ANALYZE raw.orders;
ANALYZE raw.order_items;
ANALYZE raw.order_payments;
ANALYZE raw.order_reviews;
