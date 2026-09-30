# Methodology

1. Preserve the original Olist extracts in `data/raw`.
2. Load source-aligned tables through `database/data_loading.sql`, with primary keys, foreign keys, numeric constraints, and native timestamp types.
3. Run `sql/02_data_cleaning_validation.sql` to record source-quality exceptions before analysis.
4. Use the `analytics` views as the certified reporting layer. Revenue is item price; freight is reported separately. Delivered orders are used for realized sales, RFM, and retention metrics.
5. Define late delivery only where actual delivery occurred after the promised delivery date. Treat missing delivery timestamps as exceptions, not zero-day deliveries.
6. Segment customers on the fixed dataset reference date (one day after the latest purchase) using recency, delivered-order frequency, and item revenue.

This approach keeps source data traceable while making analytical definitions explicit and reusable in SQL, Python, and Power BI.
