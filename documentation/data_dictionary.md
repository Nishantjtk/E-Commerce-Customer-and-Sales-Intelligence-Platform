# Data Dictionary

| Table | Grain | Key columns | Main analytical columns |
| --- | --- | --- | --- |
| `raw.customers` | Order-level customer record | `customer_id` (PK), `customer_unique_id` | ZIP prefix, city, state |
| `raw.orders` | Order | `order_id` (PK), `customer_id` (FK) | status; purchase, approval, carrier, customer-delivery, and estimated-delivery timestamps |
| `raw.order_items` | Item within an order | `(order_id, order_item_id)` (PK) | product, seller, shipping limit, price, freight value |
| `raw.products` | Product | `product_id` (PK) | Portuguese category, text lengths, photo count, weight, dimensions |
| `raw.sellers` | Seller | `seller_id` (PK) | ZIP prefix, city, state |
| `raw.order_payments` | Payment installment/record | `(order_id, payment_sequential)` (PK) | type, installments, value |
| `raw.order_reviews` | Source review row | generated `review_row_id` (PK), order FK | review ID, score, text, creation and response timestamps |
| `raw.geolocation` | ZIP/geographic observation | no unique source key | ZIP prefix, latitude, longitude, city, state |
| `raw.category_translation` | Category mapping | Portuguese category (PK) | English category name |

## Derived views

| View | Grain | Purpose |
| --- | --- | --- |
| `analytics.order_financials` | Order | Finance, review, and delivery KPIs |
| `analytics.order_line` | Order item | Category, product, and seller performance |
| `analytics.customer_rfm` | Unique customer | Recency, frequency, monetary scores and segment |
| `analytics.cohort_retention` | Cohort month × purchase month | Retention matrix input |
| `analytics.delivery_experience` | Order | Late/on-time delivery and satisfaction analysis |
| `analytics.category_experience` | Category | Certified revenue, delivery duration, late rate, and review score |
| `analytics.payment_detail` | Payment sequence | Payment method, installments, value, and order context |
| `analytics.review_detail` | Review row | Review score and order/delivery context |
| `analytics.seller_experience` | Seller | Certified seller revenue, delivery, and review metrics |
