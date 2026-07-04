-- PostgreSQL schema for the normalized churn analytics database.
-- Run order: schema.sql, constraints.sql, indexes.sql, seed.sql.

CREATE SCHEMA IF NOT EXISTS churn;
SET search_path TO churn;

DROP TABLE IF EXISTS customer_status_history CASCADE;
DROP TABLE IF EXISTS billing_profiles CASCADE;
DROP TABLE IF EXISTS customer_services CASCADE;
DROP TABLE IF EXISTS customer_accounts CASCADE;
DROP TABLE IF EXISTS demographics CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS locations CASCADE;

CREATE TABLE locations (
    location_id INTEGER NOT NULL,
    country VARCHAR(80) NOT NULL
);

CREATE TABLE customers (
    customer_id BIGINT NOT NULL,
    surname VARCHAR(120) NOT NULL,
    location_id INTEGER NOT NULL,
    source_row_number INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE demographics (
    customer_id BIGINT NOT NULL,
    gender VARCHAR(20) NOT NULL,
    age INTEGER NOT NULL,
    credit_score INTEGER NOT NULL,
    estimated_salary NUMERIC(12, 2) NOT NULL,
    risk_band VARCHAR(20) NOT NULL
);

CREATE TABLE customer_accounts (
    account_id BIGINT GENERATED ALWAYS AS IDENTITY,
    customer_id BIGINT NOT NULL,
    tenure_years INTEGER NOT NULL,
    contract_type VARCHAR(30) NOT NULL,
    is_active_member BOOLEAN NOT NULL,
    account_start_date DATE GENERATED ALWAYS AS (
        (DATE '2024-01-01' - (tenure_years * INTERVAL '1 year'))::DATE
    ) STORED
);

CREATE TABLE customer_services (
    service_id BIGINT GENERATED ALWAYS AS IDENTITY,
    customer_id BIGINT NOT NULL,
    num_products INTEGER NOT NULL,
    service_bundle VARCHAR(40) NOT NULL,
    has_credit_card BOOLEAN NOT NULL
);

CREATE TABLE billing_profiles (
    billing_id BIGINT GENERATED ALWAYS AS IDENTITY,
    customer_id BIGINT NOT NULL,
    balance NUMERIC(14, 2) NOT NULL,
    monthly_charges NUMERIC(10, 2) NOT NULL,
    total_charges NUMERIC(14, 2) NOT NULL,
    payment_method VARCHAR(40) NOT NULL,
    paperless_billing BOOLEAN NOT NULL
);

CREATE TABLE customer_status_history (
    status_id BIGINT GENERATED ALWAYS AS IDENTITY,
    customer_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL,
    exited BOOLEAN NOT NULL,
    churn_reason TEXT,
    status_date DATE NOT NULL DEFAULT DATE '2024-01-01'
);
