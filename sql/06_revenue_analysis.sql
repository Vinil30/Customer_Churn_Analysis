SET search_path TO churn;

-- Revenue composition and estimated revenue lost to churn.
WITH revenue AS (
    SELECT
        l.country,
        a.contract_type,
        b.payment_method,
        s.exited,
        b.monthly_charges,
        b.total_charges,
        CASE WHEN s.exited THEN b.monthly_charges * 12 ELSE 0 END AS annual_revenue_at_risk
    FROM customers c
    JOIN locations l ON l.location_id = c.location_id
    JOIN customer_accounts a ON a.customer_id = c.customer_id
    JOIN billing_profiles b ON b.customer_id = c.customer_id
    JOIN customer_status_history s ON s.customer_id = c.customer_id
)
SELECT
    country,
    contract_type,
    payment_method,
    COUNT(*) AS customers,
    ROUND(SUM(monthly_charges), 2) AS monthly_recurring_revenue,
    ROUND(SUM(total_charges), 2) AS booked_revenue,
    ROUND(SUM(annual_revenue_at_risk), 2) AS annual_revenue_lost_to_churn,
    ROUND(100.0 * SUM(annual_revenue_at_risk) / NULLIF(SUM(monthly_charges * 12), 0), 2)
        AS revenue_churn_pct
FROM revenue
GROUP BY country, contract_type, payment_method
ORDER BY annual_revenue_lost_to_churn DESC;

-- Top decile revenue customers by country.
SELECT *
FROM (
    SELECT
        c.customer_id,
        c.surname,
        l.country,
        b.total_charges,
        NTILE(10) OVER (PARTITION BY l.country ORDER BY b.total_charges DESC) AS revenue_decile
    FROM customers c
    JOIN locations l ON l.location_id = c.location_id
    JOIN billing_profiles b ON b.customer_id = c.customer_id
) ranked
WHERE revenue_decile = 1
ORDER BY country, total_charges DESC;
