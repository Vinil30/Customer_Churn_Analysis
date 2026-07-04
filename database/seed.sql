-- Generate seed CSVs first:
--   python database/normalize_dataset.py
--
-- Then run from the repository root with psql:
--   \i database/schema.sql
--   \i database/constraints.sql
--   \i database/indexes.sql
--   \i database/seed.sql

SET search_path TO churn;

\copy locations (location_id, country) FROM 'data/normalized/locations.csv' WITH (FORMAT csv, HEADER true);
\copy customers (customer_id, surname, location_id, source_row_number) FROM 'data/normalized/customers.csv' WITH (FORMAT csv, HEADER true);
\copy demographics (customer_id, gender, age, credit_score, estimated_salary, risk_band) FROM 'data/normalized/demographics.csv' WITH (FORMAT csv, HEADER true);
\copy customer_accounts (customer_id, tenure_years, contract_type, is_active_member) FROM 'data/normalized/accounts.csv' WITH (FORMAT csv, HEADER true);
\copy customer_services (customer_id, num_products, service_bundle, has_credit_card) FROM 'data/normalized/services.csv' WITH (FORMAT csv, HEADER true);
\copy billing_profiles (customer_id, balance, monthly_charges, total_charges, payment_method, paperless_billing) FROM 'data/normalized/billing.csv' WITH (FORMAT csv, HEADER true);
\copy customer_status_history (customer_id, status, exited, churn_reason) FROM 'data/normalized/customer_status_history.csv' WITH (FORMAT csv, HEADER true);

ANALYZE churn.locations;
ANALYZE churn.customers;
ANALYZE churn.demographics;
ANALYZE churn.customer_accounts;
ANALYZE churn.customer_services;
ANALYZE churn.billing_profiles;
ANALYZE churn.customer_status_history;
