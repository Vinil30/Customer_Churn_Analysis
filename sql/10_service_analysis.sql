SET search_path TO churn;

-- Service usage trends by bundle, product count, and customer status.
SELECT
    cs.service_bundle,
    cs.num_products,
    cs.has_credit_card,
    COUNT(*) AS customers,
    ROUND(AVG(b.monthly_charges), 2) AS avg_monthly_charges,
    ROUND(AVG(b.total_charges), 2) AS avg_total_charges,
    ROUND(100.0 * AVG(s.exited::int), 2) AS churn_rate_pct
FROM customer_services cs
JOIN billing_profiles b ON b.customer_id = cs.customer_id
JOIN customer_status_history s ON s.customer_id = cs.customer_id
GROUP BY cs.service_bundle, cs.num_products, cs.has_credit_card
ORDER BY cs.num_products DESC, churn_rate_pct DESC;

-- Bundle-level share of customers and revenue.
WITH bundle_revenue AS (
    SELECT
        cs.service_bundle,
        COUNT(*) AS customers,
        SUM(b.monthly_charges) AS mrr
    FROM customer_services cs
    JOIN billing_profiles b ON b.customer_id = cs.customer_id
    GROUP BY cs.service_bundle
)
SELECT
    service_bundle,
    customers,
    ROUND(100.0 * customers / SUM(customers) OVER (), 2) AS customer_share_pct,
    ROUND(mrr, 2) AS monthly_recurring_revenue,
    ROUND(100.0 * mrr / SUM(mrr) OVER (), 2) AS revenue_share_pct
FROM bundle_revenue
ORDER BY monthly_recurring_revenue DESC;
