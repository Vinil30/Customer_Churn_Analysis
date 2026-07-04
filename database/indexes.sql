SET search_path TO churn;

CREATE INDEX IF NOT EXISTS idx_customers_location_id ON customers (location_id);
CREATE INDEX IF NOT EXISTS idx_demographics_age ON demographics (age);
CREATE INDEX IF NOT EXISTS idx_demographics_credit_score ON demographics (credit_score);
CREATE INDEX IF NOT EXISTS idx_demographics_risk_band ON demographics (risk_band);
CREATE INDEX IF NOT EXISTS idx_accounts_contract_tenure ON customer_accounts (contract_type, tenure_years);
CREATE INDEX IF NOT EXISTS idx_accounts_active ON customer_accounts (is_active_member);
CREATE INDEX IF NOT EXISTS idx_services_bundle_products ON customer_services (service_bundle, num_products);
CREATE INDEX IF NOT EXISTS idx_billing_payment_method ON billing_profiles (payment_method);
CREATE INDEX IF NOT EXISTS idx_billing_monthly_charges ON billing_profiles (monthly_charges DESC);
CREATE INDEX IF NOT EXISTS idx_status_customer_date ON customer_status_history (customer_id, status_date DESC);
CREATE INDEX IF NOT EXISTS idx_status_exited ON customer_status_history (exited);
