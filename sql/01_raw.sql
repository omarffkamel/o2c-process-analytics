CREATE SCHEMA IF NOT EXISTS raw;

DROP TABLE IF EXISTS raw.orders;
CREATE TABLE raw.orders (
  order_id text,
  customer_id text,
  order_status text,
  order_purchase_timestamp text,
  order_approved_at text,
  order_delivered_carrier_date text,
  order_delivered_customer_date text,
  order_estimated_delivery_date text
);

COPY raw.orders FROM '/data/raw/olist_orders_dataset.csv' CSV HEADER;

DROP TABLE IF EXISTS raw.customers;
CREATE TABLE raw.customers (
  customer_id text,
  customer_unique_id text,
  customer_zip_code_prefix text,
  customer_city text,
  customer_state text
);
COPY raw.customers FROM '/data/raw/olist_customers_dataset.csv' CSV HEADER;

DROP TABLE IF EXISTS raw.geolocation;
CREATE TABLE raw.geolocation (
  geolocation_zip_code_prefix text,
  geolocation_lat text,
  geolocation_lng text,
  geolocation_city text,
  geolocation_state text
);
COPY raw.geolocation FROM '/data/raw/olist_geolocation_dataset.csv' CSV HEADER;

DROP TABLE IF EXISTS raw.order_items;
CREATE TABLE raw.order_items (
  order_id text,
  order_item_id text,
  product_id text,
  seller_id text,
  shipping_limit_date text,
  price text,
  freight_value text
);
COPY raw.order_items FROM '/data/raw/olist_order_items_dataset.csv' CSV HEADER;

DROP TABLE IF EXISTS raw.order_payments;
CREATE TABLE raw.order_payments (
  order_id text,
  payment_sequential text,
  payment_type text,
  payment_installments text,
  payment_value text
);
COPY raw.order_payments FROM '/data/raw/olist_order_payments_dataset.csv' CSV HEADER;

DROP TABLE IF EXISTS raw.order_reviews;
CREATE TABLE raw.order_reviews (
  review_id text,
  order_id text,
  review_score text,
  review_comment_title text,
  review_comment_message text,
  review_creation_date text,
  review_answer_timestamp text
);
COPY raw.order_reviews FROM '/data/raw/olist_order_reviews_dataset.csv' CSV HEADER;

DROP TABLE IF EXISTS raw.products;
CREATE TABLE raw.products (
  product_id text,
  product_category_name text,
  product_name_lenght text,
  product_description_lenght text,
  product_photos_qty text,
  product_weight_g text,
  product_length_cm text,
  product_height_cm text,
  product_width_cm text
);
COPY raw.products FROM '/data/raw/olist_products_dataset.csv' CSV HEADER;

DROP TABLE IF EXISTS raw.sellers;
CREATE TABLE raw.sellers (
  seller_id text,
  seller_zip_code_prefix text,
  seller_city text,
  seller_state text
);
COPY raw.sellers FROM '/data/raw/olist_sellers_dataset.csv' CSV HEADER;

DROP TABLE IF EXISTS raw.category_translation;
CREATE TABLE raw.category_translation (
  product_category_name text,
  product_category_name_english text
);
COPY raw.category_translation FROM '/data/raw/product_category_name_translation.csv' CSV HEADER;