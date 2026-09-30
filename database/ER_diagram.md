# Entity-Relationship Diagram

```mermaid
erDiagram
    CUSTOMERS ||--o{ ORDERS : places
    ORDERS ||--o{ ORDER_ITEMS : contains
    PRODUCTS ||--o{ ORDER_ITEMS : identifies
    SELLERS ||--o{ ORDER_ITEMS : fulfills
    ORDERS ||--o{ ORDER_PAYMENTS : paid_by
    ORDERS ||--o{ ORDER_REVIEWS : receives
    CATEGORY_TRANSLATION ||--o{ PRODUCTS : translates

    CUSTOMERS {
      varchar customer_id PK
      varchar customer_unique_id
    }
    ORDERS {
      varchar order_id PK
      varchar customer_id FK
      timestamp order_purchase_timestamp
      text order_status
    }
    ORDER_ITEMS {
      varchar order_id PK, FK
      integer order_item_id PK
      varchar product_id FK
      varchar seller_id FK
      numeric price
      numeric freight_value
    }
    PRODUCTS {
      varchar product_id PK
      text product_category_name
    }
    SELLERS {
      varchar seller_id PK
    }
    ORDER_PAYMENTS {
      varchar order_id PK, FK
      integer payment_sequential PK
      numeric payment_value
    }
    ORDER_REVIEWS {
      bigint review_row_id PK
      varchar order_id FK
      smallint review_score
    }
```

`raw.geolocation` intentionally has no enforced foreign key because the source contains multiple observations per ZIP-code prefix and must be aggregated before use as a geographic lookup.
