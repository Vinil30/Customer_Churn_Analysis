SET search_path TO churn;

-- 1. What is the overall churn rate?
SELECT
    COUNT(*) AS customers,
    SUM(exited::int) AS churned_customers,
    ROUND(100.0 * AVG(exited::int), 2) AS churn_rate_pct
FROM customer_status_history;

-- 2. Which payment methods have the highest churn?
SELECT
    payment_method,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(exited::int), 2) AS churn_rate_pct
FROM vw_customer_analytics
GROUP BY payment_method
ORDER BY churn_rate_pct DESC;

-- 3. Which contracts lose the most revenue to churn?
SELECT
    contract_type,
    ROUND(SUM(CASE WHEN exited THEN monthly_charges * 12 ELSE 0 END), 2) AS annual_revenue_lost,
    ROUND(100.0 * AVG(exited::int), 2) AS churn_rate_pct
FROM vw_customer_analytics
GROUP BY contract_type
ORDER BY annual_revenue_lost DESC;

-- 4. Which demographic groups are highest risk?
SELECT
    gender,
    risk_band,
    CASE
        WHEN age < 30 THEN '18-29'
        WHEN age < 45 THEN '30-44'
        WHEN age < 60 THEN '45-59'
        ELSE '60+'
    END AS age_band,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(exited::int), 2) AS churn_rate_pct
FROM vw_customer_analytics
GROUP BY gender, risk_band, age_band
HAVING COUNT(*) >= 30
ORDER BY churn_rate_pct DESC;

-- 5. Which retained customers look most valuable for retention campaigns?
SELECT
    customer_id,
    surname,
    country,
    contract_type,
    service_bundle,
    monthly_charges,
    total_charges
FROM vw_customer_analytics
WHERE exited = false
  AND total_charges > (SELECT percentile_cont(0.90) WITHIN GROUP (ORDER BY total_charges) FROM billing_profiles)
ORDER BY monthly_charges DESC
LIMIT 50;
