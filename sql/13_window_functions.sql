SET search_path TO churn;

-- Rank customers inside each country by revenue and compare with neighbors.
SELECT
    customer_id,
    surname,
    country,
    total_charges,
    monthly_charges,
    RANK() OVER (PARTITION BY country ORDER BY total_charges DESC) AS revenue_rank,
    DENSE_RANK() OVER (PARTITION BY country ORDER BY monthly_charges DESC) AS mrr_dense_rank,
    LAG(total_charges) OVER (PARTITION BY country ORDER BY total_charges DESC) AS prior_customer_revenue,
    LEAD(total_charges) OVER (PARTITION BY country ORDER BY total_charges DESC) AS next_customer_revenue,
    ROUND(
        total_charges - AVG(total_charges) OVER (PARTITION BY country),
        2
    ) AS revenue_vs_country_avg
FROM vw_customer_analytics
ORDER BY country, revenue_rank
LIMIT 200;

-- Percentile-based churn risk bands from observed revenue and tenure.
SELECT
    customer_id,
    surname,
    contract_type,
    tenure_years,
    monthly_charges,
    NTILE(4) OVER (ORDER BY tenure_years ASC, monthly_charges DESC) AS risk_quartile,
    CUME_DIST() OVER (ORDER BY monthly_charges) AS monthly_charge_cume_dist
FROM vw_customer_analytics
ORDER BY risk_quartile, monthly_charges DESC;
