SET search_path TO churn;

-- Executive customer base profile by geography.
SELECT
    l.country,
    COUNT(*) AS customers,
    ROUND(AVG(d.age), 1) AS avg_age,
    ROUND(AVG(d.credit_score), 1) AS avg_credit_score,
    ROUND(AVG(a.tenure_years), 1) AS avg_tenure_years,
    ROUND(AVG(b.monthly_charges), 2) AS avg_monthly_charges,
    ROUND(100.0 * AVG(s.exited::int), 2) AS churn_rate_pct
FROM customers c
JOIN locations l ON l.location_id = c.location_id
JOIN demographics d ON d.customer_id = c.customer_id
JOIN customer_accounts a ON a.customer_id = c.customer_id
JOIN billing_profiles b ON b.customer_id = c.customer_id
JOIN customer_status_history s ON s.customer_id = c.customer_id
GROUP BY l.country
ORDER BY customers DESC;

-- Customers with premium revenue but weak engagement.
SELECT
    c.customer_id,
    c.surname,
    l.country,
    a.contract_type,
    a.tenure_years,
    b.monthly_charges,
    cs.service_bundle,
    s.status
FROM customers c
JOIN locations l ON l.location_id = c.location_id
JOIN customer_accounts a ON a.customer_id = c.customer_id
JOIN billing_profiles b ON b.customer_id = c.customer_id
JOIN customer_services cs ON cs.customer_id = c.customer_id
JOIN customer_status_history s ON s.customer_id = c.customer_id
WHERE b.monthly_charges >= (
    SELECT percentile_cont(0.90) WITHIN GROUP (ORDER BY monthly_charges)
    FROM billing_profiles
)
AND a.is_active_member = false
ORDER BY b.monthly_charges DESC
LIMIT 50;
