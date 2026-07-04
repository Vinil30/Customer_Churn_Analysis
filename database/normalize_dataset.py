"""Normalize the source churn CSV into relational seed files.

The ANN notebooks intentionally continue to read the original denormalized CSV.
This script only prepares PostgreSQL-friendly CSV files for the SQL analytics
layer.
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
SOURCE_CSV = ROOT / "data" / "Churn_Modelling.csv"
OUTPUT_DIR = ROOT / "data" / "normalized"


def contract_type(tenure: int) -> str:
    if tenure <= 2:
        return "Month-to-month"
    if tenure <= 6:
        return "One year"
    return "Two year"


def payment_method(has_cr_card: int, balance: float) -> str:
    if has_cr_card == 1 and balance > 0:
        return "Credit card"
    if has_cr_card == 1:
        return "Debit card"
    if balance > 0:
        return "Bank transfer"
    return "Electronic check"


def service_bundle(num_products: int, balance: float) -> str:
    if num_products >= 3:
        return "Premium bundle"
    if num_products == 2:
        return "Dual service"
    if balance > 0:
        return "Core service"
    return "Starter service"


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    df = pd.read_csv(SOURCE_CSV)

    df = df.rename(
        columns={
            "RowNumber": "source_row_number",
            "CustomerId": "customer_id",
            "Surname": "surname",
            "CreditScore": "credit_score",
            "Geography": "country",
            "Gender": "gender",
            "Age": "age",
            "Tenure": "tenure_years",
            "Balance": "balance",
            "NumOfProducts": "num_products",
            "HasCrCard": "has_credit_card",
            "IsActiveMember": "is_active_member",
            "EstimatedSalary": "estimated_salary",
            "Exited": "exited",
        }
    )

    locations = (
        df[["country"]]
        .drop_duplicates()
        .sort_values("country")
        .reset_index(drop=True)
        .reset_index()
        .rename(columns={"index": "location_id"})
    )
    locations["location_id"] += 1

    df = df.merge(locations, on="country", how="left")
    df["contract_type"] = df["tenure_years"].apply(contract_type)
    df["payment_method"] = df.apply(
        lambda row: payment_method(row["has_credit_card"], row["balance"]), axis=1
    )
    df["service_bundle"] = df.apply(
        lambda row: service_bundle(row["num_products"], row["balance"]), axis=1
    )
    df["paperless_billing"] = (df["estimated_salary"] >= df["estimated_salary"].median()).astype(int)
    df["monthly_charges"] = (
        (df["estimated_salary"] / 1200) + (df["num_products"] * 12) + (df["balance"] * 0.00015)
    ).round(2)
    df["total_charges"] = (df["monthly_charges"] * (df["tenure_years"] * 12).clip(lower=1)).round(2)
    df["risk_band"] = pd.cut(
        df["credit_score"],
        bins=[0, 579, 669, 739, 799, 900],
        labels=["Very High", "High", "Medium", "Low", "Very Low"],
        include_lowest=True,
    ).astype(str)

    customers = df[
        ["customer_id", "surname", "location_id", "source_row_number"]
    ].sort_values("customer_id")
    demographics = df[
        ["customer_id", "gender", "age", "credit_score", "estimated_salary", "risk_band"]
    ].sort_values("customer_id")
    accounts = df[
        ["customer_id", "tenure_years", "contract_type", "is_active_member"]
    ].sort_values("customer_id")
    services = df[
        ["customer_id", "num_products", "service_bundle", "has_credit_card"]
    ].sort_values("customer_id")
    billing = df[
        [
            "customer_id",
            "balance",
            "monthly_charges",
            "total_charges",
            "payment_method",
            "paperless_billing",
        ]
    ].sort_values("customer_id")
    status = df[["customer_id", "exited"]].copy()
    status["status"] = status["exited"].map({1: "Churned", 0: "Retained"})
    status["churn_reason"] = status.apply(
        lambda row: "Observed churn in source dataset" if row["exited"] == 1 else None,
        axis=1,
    )
    status = status[["customer_id", "status", "exited", "churn_reason"]].sort_values("customer_id")

    exports = {
        "locations.csv": locations,
        "customers.csv": customers,
        "demographics.csv": demographics,
        "accounts.csv": accounts,
        "services.csv": services,
        "billing.csv": billing,
        "customer_status_history.csv": status,
    }

    for filename, table in exports.items():
        table.to_csv(OUTPUT_DIR / filename, index=False)

    print(f"Normalized {len(df):,} source rows into {len(exports)} CSV files at {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
