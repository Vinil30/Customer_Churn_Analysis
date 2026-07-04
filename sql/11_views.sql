SET search_path TO churn;

CREATE OR REPLACE VIEW vw_customer_analytics AS
SELECT
    c.customer_id,
    c.surname,
    l.country,
    d.gender,
    d.age,
    d.credit_score,
    d.estimated_salary,
    d.risk_band,
    a.tenure_years,
    a.contract_type,
    a.is_active_member,
    cs.num_products,
    cs.service_bundle,
    cs.has_credit_card,
    b.balance,
    b.monthly_charges,
    b.total_charges,
    b.payment_method,
    b.paperless_billing,
    s.status,
    s.exited
FROM customers c
JOIN locations l ON l.location_id = c.location_id
JOIN demographics d ON d.customer_id = c.customer_id
JOIN customer_accounts a ON a.customer_id = c.customer_id
JOIN customer_services cs ON cs.customer_id = c.customer_id
JOIN billing_profiles b ON b.customer_id = c.customer_id
JOIN customer_status_history s ON s.customer_id = c.customer_id;

-- Reconstructs the ANN training shape from normalized tables.
CREATE OR REPLACE VIEW vw_ann_training_dataset AS
SELECT
    c.source_row_number AS "RowNumber",
    c.customer_id AS "CustomerId",
    c.surname AS "Surname",
    d.credit_score AS "CreditScore",
    l.country AS "Geography",
    d.gender AS "Gender",
    d.age AS "Age",
    a.tenure_years AS "Tenure",
    b.balance AS "Balance",
    cs.num_products AS "NumOfProducts",
    cs.has_credit_card::int AS "HasCrCard",
    a.is_active_member::int AS "IsActiveMember",
    d.estimated_salary AS "EstimatedSalary",
    s.exited::int AS "Exited"
FROM customers c
JOIN locations l ON l.location_id = c.location_id
JOIN demographics d ON d.customer_id = c.customer_id
JOIN customer_accounts a ON a.customer_id = c.customer_id
JOIN customer_services cs ON cs.customer_id = c.customer_id
JOIN billing_profiles b ON b.customer_id = c.customer_id
JOIN customer_status_history s ON s.customer_id = c.customer_id;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_monthly_kpis AS
SELECT
    DATE_TRUNC('month', s.status_date)::date AS kpi_month,
    COUNT(*) AS customers,
    SUM(s.exited::int) AS churned_customers,
    ROUND(100.0 * AVG(s.exited::int), 2) AS churn_rate_pct,
    ROUND(SUM(b.monthly_charges), 2) AS monthly_recurring_revenue,
    ROUND(SUM(CASE WHEN s.exited THEN b.monthly_charges * 12 ELSE 0 END), 2) AS annual_revenue_at_risk
FROM customer_status_history s
JOIN billing_profiles b ON b.customer_id = s.customer_id
GROUP BY DATE_TRUNC('month', s.status_date)::date;
