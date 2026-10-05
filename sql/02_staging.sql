
CREATE SCHEMA IF NOT EXISTS staging;

DROP TABLE IF EXISTS staging.orders CASCADE;
CREATE TABLE staging.orders AS
SELECT
  order_id,
  customer_id,
  order_status,
  order_purchase_timestamp::timestamp      AS purchased_at,
  order_approved_at::timestamp             AS approved_at,
  order_delivered_carrier_date::timestamp  AS shipped_at,
  order_delivered_customer_date::timestamp AS delivered_at,
  order_estimated_delivery_date::timestamp AS estimated_delivery_at
FROM raw.orders;

ALTER TABLE staging.orders ADD PRIMARY KEY (order_id);

DROP TABLE IF EXISTS staging.order_items CASCADE;
CREATE TABLE staging.order_items AS
SELECT
  order_id,
  order_item_id::int             AS item_number,
  product_id,
  seller_id,
  shipping_limit_date::timestamp AS shipping_limit_at,
  price::numeric(10,2)           AS price,
  freight_value::numeric(10,2)   AS freight_value
FROM raw.order_items;

ALTER TABLE staging.order_items ADD PRIMARY KEY (order_id, item_number);
DROP TABLE IF EXISTS staging.order_payments CASCADE;
CREATE TABLE staging.order_payments AS
SELECT
  order_id,
  payment_sequential::int       AS payment_number,
  payment_type,
  payment_installments::int     AS installments,
  payment_value::numeric(10,2)  AS payment_value
FROM raw.order_payments;

ALTER TABLE staging.order_payments ADD PRIMARY KEY (order_id, payment_number);

DROP TABLE IF EXISTS staging.customers CASCADE;
CREATE TABLE staging.customers AS
SELECT
  customer_id,
  customer_unique_id,
  customer_zip_code_prefix AS zip_prefix,
  customer_city            AS city,
  customer_state           AS state
FROM raw.customers;

ALTER TABLE staging.customers ADD PRIMARY KEY (customer_id);

DROP TABLE IF EXISTS staging.sellers CASCADE;
CREATE TABLE staging.sellers AS
SELECT
  seller_id,
  seller_zip_code_prefix AS zip_prefix,
  seller_city            AS city,
  seller_state           AS state
FROM raw.sellers;

ALTER TABLE staging.sellers ADD PRIMARY KEY (seller_id);

DROP TABLE IF EXISTS staging.products CASCADE;
CREATE TABLE staging.products AS
SELECT
  p.product_id,
  COALESCE(t.product_category_name_english,
           p.product_category_name,
           'unknown') AS category
FROM raw.products p
LEFT JOIN raw.category_translation t
  ON t.product_category_name = p.product_category_name;

ALTER TABLE staging.products ADD PRIMARY KEY (product_id);

DROP TABLE IF EXISTS staging.order_reviews CASCADE;
CREATE TABLE staging.order_reviews AS
WITH ranked AS (
  SELECT
    order_id,
    review_id,
    review_score::int                  AS review_score,
    review_creation_date::timestamp    AS review_created_at,
    review_answer_timestamp::timestamp AS review_answered_at,
    ROW_NUMBER() OVER (
      PARTITION BY order_id
      ORDER BY review_answer_timestamp::timestamp DESC, review_id
    ) AS rn
  FROM raw.order_reviews
)
SELECT order_id, review_id, review_score, review_created_at, review_answered_at
FROM ranked
WHERE rn = 1;

ALTER TABLE staging.order_reviews ADD PRIMARY KEY (order_id);