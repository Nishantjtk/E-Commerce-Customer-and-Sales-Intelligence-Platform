\set ON_ERROR_STOP on
\i database/schema.sql

CREATE TABLE IF NOT EXISTS raw.customers (
  customer_id varchar(32) PRIMARY KEY,
  customer_unique_id varchar(32) NOT NULL,
  customer_zip_code_prefix integer,
  customer_city text,
  customer_state char(2)
);

CREATE TABLE IF NOT EXISTS raw.sellers (
  seller_id varchar(32) PRIMARY KEY,
  seller_zip_code_prefix integer,
  seller_city text,
  seller_state char(2)
);

CREATE TABLE IF NOT EXISTS raw.products (
  product_id varchar(32) PRIMARY KEY,
  product_category_name text,
  product_name_lenght integer,
  product_description_lenght integer,
  product_photos_qty integer,
  product_weight_g numeric,
  product_length_cm numeric,
  product_height_cm numeric,
  product_width_cm numeric
);

CREATE TABLE IF NOT EXISTS raw.category_translation (
  product_category_name text PRIMARY KEY,
  product_category_name_english text NOT NULL
);

CREATE TABLE IF NOT EXISTS raw.orders (
  order_id varchar(32) PRIMARY KEY,
  customer_id varchar(32) NOT NULL REFERENCES raw.customers(customer_id),
  order_status text NOT NULL,
  order_purchase_timestamp timestamp NOT NULL,
  order_approved_at timestamp,
  order_delivered_carrier_date timestamp,
  order_delivered_customer_date timestamp,
  order_estimated_delivery_date timestamp
);

CREATE TABLE IF NOT EXISTS raw.order_items (
  order_id varchar(32) NOT NULL REFERENCES raw.orders(order_id),
  order_item_id integer NOT NULL,
  product_id varchar(32) NOT NULL REFERENCES raw.products(product_id),
  seller_id varchar(32) NOT NULL REFERENCES raw.sellers(seller_id),
  shipping_limit_date timestamp,
  price numeric(12,2) NOT NULL CHECK (price >= 0),
  freight_value numeric(12,2) NOT NULL CHECK (freight_value >= 0),
  PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE IF NOT EXISTS raw.order_payments (
  order_id varchar(32) NOT NULL REFERENCES raw.orders(order_id),
  payment_sequential integer NOT NULL,
  payment_type text NOT NULL,
  payment_installments integer NOT NULL CHECK (payment_installments >= 0),
  payment_value numeric(12,2) NOT NULL CHECK (payment_value >= 0),
  PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE IF NOT EXISTS raw.order_reviews (
  review_row_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  review_id varchar(32) NOT NULL,
  order_id varchar(32) NOT NULL REFERENCES raw.orders(order_id),
  review_score smallint NOT NULL CHECK (review_score BETWEEN 1 AND 5),
  review_comment_title text,
  review_comment_message text,
  review_creation_date timestamp,
  review_answer_timestamp timestamp
);

CREATE TABLE IF NOT EXISTS raw.geolocation (
  geolocation_zip_code_prefix integer NOT NULL,
  geolocation_lat numeric(10,7),
  geolocation_lng numeric(10,7),
  geolocation_city text,
  geolocation_state char(2)
);

CREATE INDEX IF NOT EXISTS ix_orders_purchase_date ON raw.orders(order_purchase_timestamp);
CREATE INDEX IF NOT EXISTS ix_orders_customer ON raw.orders(customer_id);
CREATE INDEX IF NOT EXISTS ix_order_items_product ON raw.order_items(product_id);
CREATE INDEX IF NOT EXISTS ix_order_items_seller ON raw.order_items(seller_id);
CREATE INDEX IF NOT EXISTS ix_reviews_order ON raw.order_reviews(order_id);
