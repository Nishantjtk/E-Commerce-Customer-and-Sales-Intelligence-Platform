# E-Commerce Customer and Sales Intelligence Platform

An end-to-end business intelligence project based on the Olist Brazilian E-Commerce public dataset. It unifies customer, order, product, seller, payment, review, and delivery data in PostgreSQL for sales intelligence, customer analytics, operational analysis, and Power BI reporting.

## Current build status

The source data is loaded into PostgreSQL and the certified analytical views are available. The current delivered-order baseline is **96,478 orders**, **R$13,221,498.11** item revenue, **93,358 unique customers**, **R$137.04** average item-order value, and **4.09/5** average review score.

| Area | Status |
| --- | --- |
| Raw source data and relational PostgreSQL model | Complete |
| SQL loading, validation, and business-analysis queries | Complete |
| Analytical views for RFM, cohorts, delivery, and reporting | Complete |
| Reproducible Python analytics scripts | Complete; require local execution |
| Power BI model, DAX, and build specification | Complete; `.pbix` requires local manual creation |

## Repository layout

```text
data/raw/           Original Olist CSV extracts
database/           Schema, table creation, loading, and reporting views
sql/                Business analysis queries (01–10)
documentation/      Data dictionary, model, and methodology
python/             Reserved for reproducible notebooks
output/             Derived CSV outputs
powerbi/             Power BI model and screenshots
insights/            Business findings and recommendations
```

## Database setup

Run these commands from the repository root, substituting a secure local password prompt or environment variable rather than committing credentials.

```powershell
psql -h localhost -p 5433 -U postgres -d ecommerce_intelligence -f database/table_creation.sql
psql -h localhost -p 5433 -U postgres -d ecommerce_intelligence -f database/data_loading.sql
psql -h localhost -p 5433 -U postgres -d ecommerce_intelligence -f database/analytics_views.sql
```

Then execute individual files in `sql/` to answer business questions. Start with `sql/02_data_cleaning_validation.sql` before publishing metrics.

## Metric definitions

- **Revenue:** sum of order-item price for delivered orders; freight is a separate metric.
- **AOV:** average delivered-order item revenue.
- **Customer:** `customer_unique_id`, never the order-level `customer_id`.
- **Late delivery:** actual customer-delivery timestamp after estimated delivery date.
- **RFM frequency:** count of delivered orders; reference date is one day after the last dataset purchase.

See [methodology](documentation/methodology.md) and [data model](documentation/data_model.md) for the full analytical contract.

For Python execution, see [python/README.md](python/README.md). For the Power BI build and validation procedure, see [powerbi/dashboard_specification.md](powerbi/dashboard_specification.md).
