SET search_path TO churn;

ALTER TABLE locations
    ADD CONSTRAINT pk_locations PRIMARY KEY (location_id),
    ADD CONSTRAINT uq_locations_country UNIQUE (country);

ALTER TABLE customers
    ADD CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    ADD CONSTRAINT uq_customers_source_row UNIQUE (source_row_number),
    ADD CONSTRAINT fk_customers_location
        FOREIGN KEY (location_id) REFERENCES locations (location_id),
    ADD CONSTRAINT chk_customers_source_row_positive CHECK (source_row_number > 0);

ALTER TABLE demographics
    ADD CONSTRAINT pk_demographics PRIMARY KEY (customer_id),
    ADD CONSTRAINT fk_demographics_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id) ON DELETE CASCADE,
    ADD CONSTRAINT chk_demographics_gender CHECK (gender IN ('Female', 'Male')),
    ADD CONSTRAINT chk_demographics_age CHECK (age BETWEEN 18 AND 100),
    ADD CONSTRAINT chk_demographics_credit_score CHECK (credit_score BETWEEN 300 AND 900),
    ADD CONSTRAINT chk_demographics_salary CHECK (estimated_salary >= 0),
    ADD CONSTRAINT chk_demographics_risk_band
        CHECK (risk_band IN ('Very High', 'High', 'Medium', 'Low', 'Very Low'));

ALTER TABLE customer_accounts
    ADD CONSTRAINT pk_customer_accounts PRIMARY KEY (account_id),
    ADD CONSTRAINT uq_customer_accounts_customer UNIQUE (customer_id),
    ADD CONSTRAINT fk_customer_accounts_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id) ON DELETE CASCADE,
    ADD CONSTRAINT chk_customer_accounts_tenure CHECK (tenure_years BETWEEN 0 AND 20),
    ADD CONSTRAINT chk_customer_accounts_contract
        CHECK (contract_type IN ('Month-to-month', 'One year', 'Two year'));

ALTER TABLE customer_services
    ADD CONSTRAINT pk_customer_services PRIMARY KEY (service_id),
    ADD CONSTRAINT uq_customer_services_customer UNIQUE (customer_id),
    ADD CONSTRAINT fk_customer_services_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id) ON DELETE CASCADE,
    ADD CONSTRAINT chk_customer_services_products CHECK (num_products BETWEEN 1 AND 4),
    ADD CONSTRAINT chk_customer_services_bundle
        CHECK (service_bundle IN ('Starter service', 'Core service', 'Dual service', 'Premium bundle'));

ALTER TABLE billing_profiles
    ADD CONSTRAINT pk_billing_profiles PRIMARY KEY (billing_id),
    ADD CONSTRAINT uq_billing_profiles_customer UNIQUE (customer_id),
    ADD CONSTRAINT fk_billing_profiles_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id) ON DELETE CASCADE,
    ADD CONSTRAINT chk_billing_profiles_balance CHECK (balance >= 0),
    ADD CONSTRAINT chk_billing_profiles_monthly CHECK (monthly_charges >= 0),
    ADD CONSTRAINT chk_billing_profiles_total CHECK (total_charges >= 0),
    ADD CONSTRAINT chk_billing_profiles_payment
        CHECK (payment_method IN ('Credit card', 'Debit card', 'Bank transfer', 'Electronic check'));

ALTER TABLE customer_status_history
    ADD CONSTRAINT pk_customer_status_history PRIMARY KEY (status_id),
    ADD CONSTRAINT fk_customer_status_history_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id) ON DELETE CASCADE,
    ADD CONSTRAINT chk_customer_status_history_status CHECK (status IN ('Retained', 'Churned'));
