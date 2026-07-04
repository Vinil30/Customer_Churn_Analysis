SET search_path TO churn;

CREATE OR REPLACE FUNCTION fn_churn_rate_by_dimension(dimension_name text)
RETURNS TABLE (
    dimension_value text,
    customers bigint,
    churned_customers bigint,
    churn_rate_pct numeric
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF dimension_name NOT IN ('country', 'contract_type', 'payment_method', 'service_bundle', 'risk_band') THEN
        RAISE EXCEPTION 'Unsupported dimension: %', dimension_name;
    END IF;

    RETURN QUERY EXECUTE format(
        'SELECT %1$I::text AS dimension_value,
                COUNT(*) AS customers,
                SUM(exited::int)::bigint AS churned_customers,
                ROUND(100.0 * AVG(exited::int), 2) AS churn_rate_pct
         FROM vw_customer_analytics
         GROUP BY %1$I
         ORDER BY churn_rate_pct DESC, customers DESC',
        dimension_name
    );
END;
$$;

CREATE OR REPLACE PROCEDURE refresh_churn_kpis()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW mv_monthly_kpis;
END;
$$;

-- Example:
-- SELECT * FROM fn_churn_rate_by_dimension('payment_method');
-- CALL refresh_churn_kpis();
