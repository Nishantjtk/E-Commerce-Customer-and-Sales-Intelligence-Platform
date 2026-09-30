WITH cohort_sizes AS (SELECT cohort_month, retained_customers AS cohort_size FROM analytics.cohort_retention WHERE cohort_index = 0)
SELECT r.cohort_month, r.cohort_index, r.retained_customers, s.cohort_size,
       ROUND(100.0 * r.retained_customers / NULLIF(s.cohort_size, 0), 2) AS retention_rate_pct
FROM analytics.cohort_retention r JOIN cohort_sizes s USING (cohort_month)
ORDER BY r.cohort_month, r.cohort_index;
