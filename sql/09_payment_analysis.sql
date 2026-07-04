SET search_path TO churn;

-- Payment behavior and churn concentration.
SELECT
    b.payment_method,
    b.paperless_billing,
    COUNT(*) AS customers,
    ROUND(AVG(b.monthly_charges), 2) AS avg_monthly_charges,
    ROUND(AVG(b.balance), 2) AS avg_balance,
    ROUND(100.0 * AVG(s.exited::int), 2) AS churn_rate_pct,
    RANK() OVER (ORDER BY AVG(s.exited::int) DESC) AS churn_rank
FROM billing_profiles b
JOIN customer_status_history s ON s.customer_id = b.customer_id
GROUP BY b.payment_method, b.paperless_billing
ORDER BY churn_rank, customers DESC;

-- Correlated subquery: customers paying more than their payment-method average.
SELECT
    c.customer_id,
    c.surname,
    b.payment_method,
    b.monthly_charges,
    s.status
FROM customers c
JOIN billing_profiles b ON b.customer_id = c.customer_id
JOIN customer_status_history s ON s.customer_id = c.customer_id
WHERE b.monthly_charges > (
    SELECT AVG(peer.monthly_charges)
    FROM billing_profiles peer
    WHERE peer.payment_method = b.payment_method
)
ORDER BY b.monthly_charges DESC
LIMIT 100;
