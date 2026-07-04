SET search_path TO churn;

-- Contract health by tenure and churn.
WITH contract_health AS (
    SELECT
        contract_type,
        tenure_years,
        COUNT(*) AS customers,
        AVG(is_active_member::int) AS active_rate,
        AVG(s.exited::int) AS churn_rate,
        AVG(b.monthly_charges) AS avg_monthly_charges
    FROM customer_accounts a
    JOIN billing_profiles b ON b.customer_id = a.customer_id
    JOIN customer_status_history s ON s.customer_id = a.customer_id
    GROUP BY contract_type, tenure_years
)
SELECT
    contract_type,
    tenure_years,
    customers,
    ROUND(active_rate * 100, 2) AS active_rate_pct,
    ROUND(churn_rate * 100, 2) AS churn_rate_pct,
    ROUND(avg_monthly_charges, 2) AS avg_monthly_charges,
    LEAD(ROUND(churn_rate * 100, 2)) OVER (PARTITION BY contract_type ORDER BY tenure_years)
        AS next_tenure_churn_rate_pct
FROM contract_health
ORDER BY contract_type, tenure_years;

-- Contract types with churn materially above the portfolio average.
SELECT
    a.contract_type,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(s.exited::int), 2) AS churn_rate_pct
FROM customer_accounts a
JOIN customer_status_history s ON s.customer_id = a.customer_id
GROUP BY a.contract_type
HAVING AVG(s.exited::int) > (
    SELECT AVG(exited::int) + 0.02 FROM customer_status_history
)
ORDER BY churn_rate_pct DESC;
