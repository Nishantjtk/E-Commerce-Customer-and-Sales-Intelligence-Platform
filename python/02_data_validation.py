"""Export the certified SQL data-validation checks as a reproducible CSV."""
from __future__ import annotations

from common import OUTPUT_DIR, ensure_output_directories, query_frame

VALIDATION_SQL = """
SELECT 'orders_without_items' AS check_name, COUNT(*)::bigint AS exceptions
FROM raw.orders o LEFT JOIN raw.order_items i USING(order_id) WHERE i.order_id IS NULL
UNION ALL
SELECT 'delivered_without_delivery_date', COUNT(*)::bigint FROM raw.orders
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NULL
UNION ALL
SELECT 'negative_delivery_duration', COUNT(*)::bigint FROM raw.orders
WHERE order_delivered_customer_date < order_purchase_timestamp
UNION ALL
SELECT 'repeat_unique_customers', COUNT(*)::bigint FROM (
  SELECT customer_unique_id FROM raw.customers GROUP BY customer_unique_id HAVING COUNT(*) > 1
) repeated_customers
ORDER BY check_name;
"""


def main() -> None:
    ensure_output_directories()
    results = query_frame(VALIDATION_SQL)
    path = OUTPUT_DIR / "data_validation_results.csv"
    results.to_csv(path, index=False)
    print(results.to_string(index=False))
    print(f"Wrote {path}")


if __name__ == "__main__":
    main()
