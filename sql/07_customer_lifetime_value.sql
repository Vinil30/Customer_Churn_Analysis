SET search_path TO churn;

-- CLV estimate using observed charges, tenure, and segment churn probability.
WITH segment_churn AS (
    SELECT
        a.contract_type,
        cs.service_bundle,
        AVG(s.exited::int)::numeric AS churn_probability
    FROM customer_accounts a
    JOIN customer_services cs ON cs.customer_id = a.customer_id
    JOIN customer_status_history s ON s.customer_id = a.customer_id
    GROUP BY a.contract_type, cs.service_bundle
),
clv AS (
    SELECT
        c.customer_id,
        c.surname,
        a.contract_type,
        cs.service_bundle,
        b.monthly_charges,
        b.total_charges,
        sc.churn_probability,
        ROUND((b.monthly_charges * 12) / NULLIF(sc.churn_probability, 0.01), 2) AS estimated_clv
    FROM customers c
    JOIN customer_accounts a ON a.customer_id = c.customer_id
    JOIN customer_services cs ON cs.customer_id = c.customer_id
    JOIN billing_profiles b ON b.customer_id = c.customer_id
    JOIN segment_churn sc
      ON sc.contract_type = a.contract_type
     AND sc.service_bundle = cs.service_bundle
)
SELECT
    *,
    DENSE_RANK() OVER (ORDER BY estimated_clv DESC) AS clv_rank
FROM clv
ORDER BY estimated_clv DESC
LIMIT 100;

-- CLV bands for portfolio planning.
WITH segment_churn AS (
    SELECT
        a.contract_type,
        cs.service_bundle,
        AVG(s.exited::int)::numeric AS churn_probability
    FROM customer_accounts a
    JOIN customer_services cs ON cs.customer_id = a.customer_id
    JOIN customer_status_history s ON s.customer_id = a.customer_id
    GROUP BY a.contract_type, cs.service_bundle
),
clv AS (
    SELECT
        c.customer_id,
        b.monthly_charges,
        ROUND((b.monthly_charges * 12) / NULLIF(sc.churn_probability, 0.01), 2) AS estimated_clv
    FROM customers c
    JOIN customer_accounts a ON a.customer_id = c.customer_id
    JOIN customer_services cs ON cs.customer_id = c.customer_id
    JOIN billing_profiles b ON b.customer_id = c.customer_id
    JOIN segment_churn sc
      ON sc.contract_type = a.contract_type
     AND sc.service_bundle = cs.service_bundle
),
thresholds AS (
    SELECT
        percentile_cont(0.50) WITHIN GROUP (ORDER BY estimated_clv) AS p50_clv,
        percentile_cont(0.90) WITHIN GROUP (ORDER BY estimated_clv) AS p90_clv
    FROM clv
)
SELECT
    CASE
        WHEN estimated_clv >= p90_clv THEN 'Top 10%'
        WHEN estimated_clv >= p50_clv THEN 'Middle 40%'
        ELSE 'Bottom 50%'
    END AS clv_band,
    COUNT(*) AS customers,
    ROUND(AVG(estimated_clv), 2) AS avg_estimated_clv
FROM clv
CROSS JOIN thresholds
GROUP BY clv_band
ORDER BY avg_estimated_clv DESC;
