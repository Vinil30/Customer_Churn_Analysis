SET search_path TO churn;

-- Tenure cohorts approximate acquisition cohorts for the denormalized source data.
WITH cohorts AS (
    SELECT
        customer_id,
        DATE_TRUNC('year', account_start_date)::date AS cohort_year,
        tenure_years,
        contract_type
    FROM customer_accounts
),
cohort_metrics AS (
    SELECT
        cohort_year,
        contract_type,
        COUNT(*) AS acquired_customers,
        SUM((NOT s.exited)::int) AS retained_customers,
        SUM(s.exited::int) AS churned_customers,
        ROUND(SUM(b.total_charges), 2) AS lifetime_revenue
    FROM cohorts c
    JOIN customer_status_history s ON s.customer_id = c.customer_id
    JOIN billing_profiles b ON b.customer_id = c.customer_id
    GROUP BY cohort_year, contract_type
)
SELECT
    cohort_year,
    contract_type,
    acquired_customers,
    retained_customers,
    churned_customers,
    ROUND(100.0 * retained_customers / acquired_customers, 2) AS retention_rate_pct,
    ROUND(lifetime_revenue / acquired_customers, 2) AS revenue_per_acquired_customer,
    LAG(ROUND(100.0 * retained_customers / acquired_customers, 2))
        OVER (PARTITION BY contract_type ORDER BY cohort_year) AS prior_cohort_retention_pct
FROM cohort_metrics
ORDER BY cohort_year, contract_type;
