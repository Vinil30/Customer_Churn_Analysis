SET search_path TO churn;

-- Segment customers by value, engagement, and churn outcome.
WITH thresholds AS (
    SELECT
        percentile_cont(0.50) WITHIN GROUP (ORDER BY total_charges) AS p50_total_charges,
        percentile_cont(0.80) WITHIN GROUP (ORDER BY total_charges) AS p80_total_charges
    FROM billing_profiles
),
customer_value AS (
    SELECT
        c.customer_id,
        l.country,
        d.risk_band,
        CASE
            WHEN d.age < 30 THEN '18-29'
            WHEN d.age < 45 THEN '30-44'
            WHEN d.age < 60 THEN '45-59'
            ELSE '60+'
        END AS age_band,
        CASE
            WHEN b.total_charges >= t.p80_total_charges
                THEN 'High value'
            WHEN b.total_charges >= t.p50_total_charges
                THEN 'Mid value'
            ELSE 'Low value'
        END AS value_segment,
        a.contract_type,
        a.is_active_member,
        s.exited
    FROM customers c
    JOIN locations l ON l.location_id = c.location_id
    JOIN demographics d ON d.customer_id = c.customer_id
    JOIN customer_accounts a ON a.customer_id = c.customer_id
    JOIN billing_profiles b ON b.customer_id = c.customer_id
    JOIN customer_status_history s ON s.customer_id = c.customer_id
    CROSS JOIN thresholds t
)
SELECT
    country,
    age_band,
    risk_band,
    value_segment,
    contract_type,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(is_active_member::int), 2) AS active_rate_pct,
    ROUND(100.0 * AVG(exited::int), 2) AS churn_rate_pct,
    DENSE_RANK() OVER (PARTITION BY country ORDER BY COUNT(*) DESC) AS segment_size_rank
FROM customer_value
GROUP BY country, age_band, risk_band, value_segment, contract_type
HAVING COUNT(*) >= 10
ORDER BY churn_rate_pct DESC, customers DESC;
