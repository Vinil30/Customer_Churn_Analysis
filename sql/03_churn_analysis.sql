SET search_path TO churn;

-- Churn diagnostics by contract, payment method, country, and service bundle.
WITH churn_base AS (
    SELECT
        c.customer_id,
        l.country,
        a.contract_type,
        a.tenure_years,
        b.payment_method,
        cs.service_bundle,
        d.gender,
        d.risk_band,
        s.exited
    FROM customers c
    JOIN locations l ON l.location_id = c.location_id
    JOIN demographics d ON d.customer_id = c.customer_id
    JOIN customer_accounts a ON a.customer_id = c.customer_id
    JOIN billing_profiles b ON b.customer_id = c.customer_id
    JOIN customer_services cs ON cs.customer_id = c.customer_id
    JOIN customer_status_history s ON s.customer_id = c.customer_id
)
SELECT
    country,
    contract_type,
    payment_method,
    service_bundle,
    COUNT(*) AS customers,
    SUM(exited::int) AS churned_customers,
    ROUND(100.0 * AVG(exited::int), 2) AS churn_rate_pct,
    ROUND(
        100.0 * AVG(exited::int)
        - AVG(AVG(exited::int)) OVER () * 100.0,
        2
    ) AS churn_rate_vs_portfolio_pp
FROM churn_base
GROUP BY country, contract_type, payment_method, service_bundle
HAVING COUNT(*) >= 20
ORDER BY churn_rate_pct DESC, customers DESC;

-- Customers in groups with above-average churn.
WITH churn_base AS (
    SELECT
        c.customer_id,
        l.country,
        a.contract_type,
        a.tenure_years,
        b.payment_method,
        cs.service_bundle,
        d.gender,
        d.risk_band,
        s.exited
    FROM customers c
    JOIN locations l ON l.location_id = c.location_id
    JOIN demographics d ON d.customer_id = c.customer_id
    JOIN customer_accounts a ON a.customer_id = c.customer_id
    JOIN billing_profiles b ON b.customer_id = c.customer_id
    JOIN customer_services cs ON cs.customer_id = c.customer_id
    JOIN customer_status_history s ON s.customer_id = c.customer_id
)
SELECT cb.*
FROM churn_base cb
WHERE EXISTS (
    SELECT 1
    FROM churn_base peer
    WHERE peer.contract_type = cb.contract_type
      AND peer.payment_method = cb.payment_method
    GROUP BY peer.contract_type, peer.payment_method
    HAVING AVG(peer.exited::int) > (SELECT AVG(exited::int) FROM churn_base)
)
ORDER BY cb.exited DESC, cb.tenure_years ASC;
