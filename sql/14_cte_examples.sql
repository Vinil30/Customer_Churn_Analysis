SET search_path TO churn;

-- CTE pipeline for high-risk customer targeting.
WITH portfolio_churn AS (
    SELECT AVG(exited::int) AS churn_rate
    FROM customer_status_history
),
segment_churn AS (
    SELECT
        v.country,
        v.contract_type,
        v.payment_method,
        v.service_bundle,
        COUNT(*) AS customers,
        AVG(v.exited::int) AS churn_rate
    FROM vw_customer_analytics v
    GROUP BY v.country, v.contract_type, v.payment_method, v.service_bundle
),
above_average_segments AS (
    SELECT sc.*
    FROM segment_churn sc
    CROSS JOIN portfolio_churn pc
    WHERE sc.customers >= 20
      AND sc.churn_rate > pc.churn_rate
),
target_customers AS (
    SELECT
        v.customer_id,
        v.surname,
        v.country,
        v.contract_type,
        v.payment_method,
        v.service_bundle,
        v.monthly_charges,
        aas.churn_rate
    FROM vw_customer_analytics v
    JOIN above_average_segments aas
      ON aas.country = v.country
     AND aas.contract_type = v.contract_type
     AND aas.payment_method = v.payment_method
     AND aas.service_bundle = v.service_bundle
    WHERE v.exited = false
)
SELECT *
FROM target_customers
ORDER BY churn_rate DESC, monthly_charges DESC
LIMIT 100;

-- Recursive CTE: generate tenure buckets and join observed churn rates.
WITH RECURSIVE tenure_buckets(bucket_start, bucket_end) AS (
    SELECT 0, 1
    UNION ALL
    SELECT bucket_end + 1, bucket_end + 2
    FROM tenure_buckets
    WHERE bucket_end < 10
),
tenure_metrics AS (
    SELECT
        tb.bucket_start,
        tb.bucket_end,
        COUNT(v.customer_id) AS customers,
        ROUND(100.0 * AVG(v.exited::int), 2) AS churn_rate_pct
    FROM tenure_buckets tb
    LEFT JOIN vw_customer_analytics v
      ON v.tenure_years BETWEEN tb.bucket_start AND tb.bucket_end
    GROUP BY tb.bucket_start, tb.bucket_end
)
SELECT *
FROM tenure_metrics
ORDER BY bucket_start;
