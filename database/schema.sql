-- E-Commerce Customer and Sales Intelligence Platform
-- PostgreSQL 18+ logical model. Run table_creation.sql before data_loading.sql.

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS analytics;

COMMENT ON SCHEMA raw IS 'Source-aligned Olist tables loaded from the original CSV extracts.';
COMMENT ON SCHEMA analytics IS 'Business-ready views and derived analytical outputs.';
