# Data Model

The PostgreSQL model separates source-aligned transactional data (`raw`) from reusable business views (`analytics`). `raw.orders` is the central transaction table. Customers, products, sellers and category translations are dimensions; order items, payments and reviews are order-level facts.

```text
customers 1 ─── * orders 1 ─── * order_items * ─── 1 products
                     │              │
                     │              └────────────── * sellers
                     ├─── * order_payments
                     └─── * order_reviews
products * ─── 1 category_translation
```

`customer_id` identifies an order-level customer record. `customer_unique_id` identifies the person across orders and is the sole customer key for RFM and cohort analysis. `order_items` has a composite primary key of `(order_id, order_item_id)`; payments use `(order_id, payment_sequential)`. Reviews use a generated row key because a review identifier/order combination is not guaranteed to be unique in the source.

Business views:

- `analytics.order_financials`: one row per order with item, payment, review, and delivery measures.
- `analytics.order_line`: one row per item for category, product, and seller analysis.
- `analytics.customer_rfm`: one row per unique customer with scored RFM segments.
- `analytics.cohort_retention`: long-form cohort data for a Power BI retention matrix.
- `analytics.delivery_experience`: delivery status and satisfaction context.
- `analytics.category_experience`: category-level revenue, delivery, and review metrics at a certified category grain.
- `analytics.payment_detail`: payment-sequence detail with safely denormalized order context.
- `analytics.review_detail`: review-row detail with delivery context.
- `analytics.seller_experience`: seller-level revenue, delivery, and review metrics at a certified seller grain.
