SET search_path TO churn;

-- Retention performance for customer engagement and contract choices.
WITH retention AS (
    SELECT
        a.contract_type,
        a.is_active_member,
        cs.service_bundle,
        COUNT(*) AS customers,
        SUM((NOT s.exited)::int) AS retained_customers,
        SUM(s.exited::int) AS churned_customers
    FROM customer_accounts a
    JOIN customer_services cs ON cs.customer_id = a.customer_id
    JOIN customer_status_history s ON s.customer_id = a.customer_id
    GROUP BY a.contract_type, a.is_active_member, cs.service_bundle
)
SELECT
    contract_type,
    is_active_member,
    service_bundle,
    customers,
    retained_customers,
    churned_customers,
    ROUND(100.0 * retained_customers / customers, 2) AS retention_rate_pct,
    RANK() OVER (ORDER BY 100.0 * retained_customers / customers DESC) AS retention_rank
FROM retention
ORDER BY retention_rank, customers DESC;

-- Estimated save opportunity: churned customers whose segment retention is normally strong.
WITH segment_retention AS (
    SELECT
        a.contract_type,
        cs.service_bundle,
        ROUND(AVG((NOT s.exited)::int), 4) AS retention_rate
    FROM customer_accounts a
    JOIN customer_services cs ON cs.customer_id = a.customer_id
    JOIN customer_status_history s ON s.customer_id = a.customer_id
    GROUP BY a.contract_type, cs.service_bundle
)
SELECT
    c.customer_id,
    c.surname,
    a.contract_type,
    cs.service_bundle,
    b.monthly_charges,
    sr.retention_rate
FROM customers c
JOIN customer_accounts a ON a.customer_id = c.customer_id
JOIN customer_services cs ON cs.customer_id = c.customer_id
JOIN billing_profiles b ON b.customer_id = c.customer_id
JOIN customer_status_history s ON s.customer_id = c.customer_id
JOIN segment_retention sr
  ON sr.contract_type = a.contract_type
 AND sr.service_bundle = cs.service_bundle
WHERE s.exited = true
  AND sr.retention_rate >= 0.80
ORDER BY b.monthly_charges DESC;
