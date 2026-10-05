CREATE SCHEMA IF NOT EXISTS mart;

DROP TABLE IF EXISTS mart.event_log CASCADE;
CREATE TABLE mart.event_log AS
WITH events AS (
  SELECT order_id AS case_id, 1 AS step, 'Order placed' AS activity, purchased_at AS event_at
  FROM staging.orders
  UNION ALL
  SELECT order_id, 2, 'Payment approved', approved_at FROM staging.orders
  UNION ALL
  SELECT order_id, 3, 'Handed to carrier', shipped_at FROM staging.orders
  UNION ALL
  SELECT order_id, 4, 'Delivered', delivered_at FROM staging.orders
  UNION ALL
  SELECT order_id, 5, 'Review answered', review_answered_at FROM staging.order_reviews
)
SELECT
  case_id,
  ROW_NUMBER() OVER w                                   AS event_number,
  activity,
  event_at,
  LAG(activity) OVER w                                  AS previous_activity,
  round(extract(epoch FROM event_at - LAG(event_at) OVER w) / 3600, 2)
                                                        AS hours_since_previous
FROM events
WHERE event_at IS NOT NULL
WINDOW w AS (PARTITION BY case_id ORDER BY event_at, step);

ALTER TABLE mart.event_log ADD PRIMARY KEY (case_id, event_number);

DROP TABLE IF EXISTS mart.fact_orders CASCADE;
CREATE TABLE mart.fact_orders AS
WITH items AS (
  SELECT
    order_id,
    count(*)                                        AS item_count,
    sum(price)                                      AS items_value,
    sum(freight_value)                              AS freight_value,
    min(seller_id)  FILTER (WHERE item_number = 1)  AS seller_id,
    min(product_id) FILTER (WHERE item_number = 1)  AS product_id
  FROM staging.order_items
  GROUP BY order_id
),
payments AS (
  SELECT order_id, sum(payment_value) AS payment_value
  FROM staging.order_payments
  GROUP BY order_id
)
SELECT
  o.order_id,
  o.customer_id,
  i.seller_id,
  i.product_id,
  o.order_status,
  o.purchased_at::date AS purchase_date,
  o.purchased_at,
  o.approved_at,
  o.shipped_at,
  o.delivered_at,
  o.estimated_delivery_at,
  i.item_count,
  i.items_value,
  i.freight_value,
  p.payment_value,
  r.review_score,
  round(extract(epoch FROM o.approved_at  - o.purchased_at) / 3600, 2)  AS approval_hours,
  round(extract(epoch FROM o.shipped_at   - o.approved_at)  / 86400, 2) AS handover_days,
  round(extract(epoch FROM o.delivered_at - o.shipped_at)   / 86400, 2) AS transit_days,
  round(extract(epoch FROM o.delivered_at - o.purchased_at) / 86400, 2) AS lead_time_days,
  CASE
    WHEN o.delivered_at IS NULL THEN NULL
    WHEN o.delivered_at::date > o.estimated_delivery_at::date THEN 1
    ELSE 0
  END AS is_late
FROM staging.orders o
LEFT JOIN items i                ON i.order_id = o.order_id
LEFT JOIN payments p             ON p.order_id = o.order_id
LEFT JOIN staging.order_reviews r ON r.order_id = o.order_id;

ALTER TABLE mart.fact_orders ADD PRIMARY KEY (order_id);

DROP TABLE IF EXISTS mart.dim_date CASCADE;
CREATE TABLE mart.dim_date AS
SELECT
  d::date                       AS date,
  extract(year FROM d)::int     AS year,
  extract(quarter FROM d)::int  AS quarter,
  extract(month FROM d)::int    AS month_number,
  to_char(d, 'Mon')             AS month_name,
  to_char(d, 'YYYY-MM')         AS year_month,
  extract(isodow FROM d)::int   AS weekday_number,
  to_char(d, 'Dy')              AS weekday_name
FROM generate_series(
  (SELECT date_trunc('year', min(purchase_date)) FROM mart.fact_orders),
  (SELECT date_trunc('year', max(purchase_date)) + interval '1 year - 1 day' FROM mart.fact_orders),
  interval '1 day'
) AS d;

ALTER TABLE mart.dim_date ADD PRIMARY KEY (date);

DROP TABLE IF EXISTS mart.dim_customer CASCADE;
CREATE TABLE mart.dim_customer AS
SELECT customer_id, customer_unique_id, city, state
FROM staging.customers;

ALTER TABLE mart.dim_customer ADD PRIMARY KEY (customer_id);

DROP TABLE IF EXISTS mart.dim_seller CASCADE;
CREATE TABLE mart.dim_seller AS
SELECT seller_id, city, state
FROM staging.sellers;

ALTER TABLE mart.dim_seller ADD PRIMARY KEY (seller_id);

DROP TABLE IF EXISTS mart.dim_product CASCADE;
CREATE TABLE mart.dim_product AS
SELECT product_id, category
FROM staging.products;

ALTER TABLE mart.dim_product ADD PRIMARY KEY (product_id);