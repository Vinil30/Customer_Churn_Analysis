"""Generate portfolio-ready churn visualizations from the source CSV.

These charts are intentionally separate from the ANN notebooks. They support
business analysis and reporting only; model preprocessing and prediction remain
inside the ANN module.
"""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


ROOT = Path(__file__).resolve().parents[2]
SOURCE_CSV = ROOT / "data" / "Churn_Modelling.csv"
OUTPUT_DIR = ROOT / "visualizations" / "python" / "outputs"
POWERBI_DIR = ROOT / "visualizations" / "powerbi"


def add_business_fields(df: pd.DataFrame) -> pd.DataFrame:
    enriched = df.copy()
    enriched["ChurnStatus"] = enriched["Exited"].map({1: "Churned", 0: "Retained"})
    enriched["ContractType"] = pd.cut(
        enriched["Tenure"],
        bins=[-1, 2, 6, 20],
        labels=["Month-to-month", "One year", "Two year"],
    ).astype(str)
    enriched["AgeBand"] = pd.cut(
        enriched["Age"],
        bins=[17, 29, 44, 59, 100],
        labels=["18-29", "30-44", "45-59", "60+"],
    ).astype(str)
    enriched["PaymentMethod"] = enriched.apply(
        lambda row: "Credit card"
        if row["HasCrCard"] == 1 and row["Balance"] > 0
        else "Debit card"
        if row["HasCrCard"] == 1
        else "Bank transfer"
        if row["Balance"] > 0
        else "Electronic check",
        axis=1,
    )
    enriched["MonthlyCharges"] = (
        (enriched["EstimatedSalary"] / 1200)
        + (enriched["NumOfProducts"] * 12)
        + (enriched["Balance"] * 0.00015)
    ).round(2)
    enriched["AnnualRevenueAtRisk"] = (
        enriched["MonthlyCharges"] * 12 * enriched["Exited"]
    ).round(2)
    return enriched


def style_axes(ax: plt.Axes, title: str, ylabel: str | None = None) -> None:
    ax.set_title(title, fontsize=14, weight="bold", pad=12)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.grid(axis="y", alpha=0.25)
    if ylabel:
        ax.set_ylabel(ylabel)
    ax.set_xlabel("")


def save_chart(fig: plt.Figure, filename: str) -> None:
    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / filename, dpi=180, bbox_inches="tight")
    plt.close(fig)


def churn_distribution(df: pd.DataFrame) -> None:
    counts = df["ChurnStatus"].value_counts().reindex(["Retained", "Churned"])
    fig, ax = plt.subplots(figsize=(7, 5))
    bars = ax.bar(counts.index, counts.values, color=["#2E7D6E", "#C44E52"])
    style_axes(ax, "Customer Churn Distribution", "Customers")
    ax.bar_label(bars, labels=[f"{value:,}" for value in counts.values], padding=4)
    save_chart(fig, "01_churn_distribution.png")


def churn_by_geography(df: pd.DataFrame) -> None:
    rates = (
        df.groupby("Geography")["Exited"]
        .mean()
        .mul(100)
        .sort_values(ascending=False)
    )
    fig, ax = plt.subplots(figsize=(8, 5))
    bars = ax.bar(rates.index, rates.values, color="#4C78A8")
    style_axes(ax, "Churn Rate by Geography", "Churn Rate (%)")
    ax.bar_label(bars, labels=[f"{value:.1f}%" for value in rates.values], padding=4)
    save_chart(fig, "02_churn_by_geography.png")


def churn_by_contract(df: pd.DataFrame) -> None:
    summary = (
        df.groupby("ContractType")
        .agg(customers=("CustomerId", "count"), churn_rate=("Exited", "mean"))
        .reindex(["Month-to-month", "One year", "Two year"])
    )
    fig, ax = plt.subplots(figsize=(8, 5))
    bars = ax.bar(summary.index, summary["churn_rate"] * 100, color="#F58518")
    style_axes(ax, "Churn Rate by Contract Type", "Churn Rate (%)")
    ax.bar_label(
        bars,
        labels=[
            f"{rate * 100:.1f}%\n{customers:,} customers"
            for rate, customers in zip(summary["churn_rate"], summary["customers"])
        ],
        padding=4,
    )
    save_chart(fig, "03_churn_by_contract_type.png")


def churn_by_age_band(df: pd.DataFrame) -> None:
    pivot = pd.crosstab(df["AgeBand"], df["ChurnStatus"], normalize="index") * 100
    pivot = pivot.reindex(["18-29", "30-44", "45-59", "60+"])
    fig, ax = plt.subplots(figsize=(8, 5))
    pivot[["Retained", "Churned"]].plot(
        kind="bar",
        stacked=True,
        ax=ax,
        color=["#54A24B", "#E45756"],
        width=0.72,
    )
    style_axes(ax, "Customer Outcome Mix by Age Band", "Share of Age Band (%)")
    ax.legend(frameon=False, loc="upper right")
    ax.tick_params(axis="x", rotation=0)
    save_chart(fig, "04_churn_by_age_band.png")


def credit_score_balance_scatter(df: pd.DataFrame) -> None:
    sample = df.sample(n=min(2000, len(df)), random_state=42)
    colors = sample["Exited"].map({0: "#4C78A8", 1: "#E45756"})
    fig, ax = plt.subplots(figsize=(8, 5.5))
    ax.scatter(
        sample["CreditScore"],
        sample["Balance"],
        c=colors,
        alpha=0.45,
        s=18,
        linewidths=0,
    )
    style_axes(ax, "Credit Score vs Balance by Churn Outcome", "Balance")
    ax.set_xlabel("Credit Score")
    ax.ticklabel_format(axis="y", style="plain")
    save_chart(fig, "05_credit_score_vs_balance.png")


def revenue_at_risk(df: pd.DataFrame) -> None:
    risk = (
        df.groupby(["Geography", "ContractType"])["AnnualRevenueAtRisk"]
        .sum()
        .reset_index()
        .sort_values("AnnualRevenueAtRisk", ascending=False)
        .head(10)
    )
    risk["Segment"] = risk["Geography"] + " | " + risk["ContractType"]
    fig, ax = plt.subplots(figsize=(9, 5.5))
    bars = ax.barh(risk["Segment"], risk["AnnualRevenueAtRisk"], color="#B279A2")
    ax.invert_yaxis()
    style_axes(ax, "Top Revenue-at-Risk Segments", "Annual Revenue at Risk")
    ax.bar_label(bars, labels=[f"{value:,.0f}" for value in risk["AnnualRevenueAtRisk"]], padding=4)
    save_chart(fig, "06_revenue_at_risk_segments.png")


def export_powerbi_dataset(df: pd.DataFrame) -> None:
    POWERBI_DIR.mkdir(parents=True, exist_ok=True)
    columns = [
        "CustomerId",
        "Surname",
        "CreditScore",
        "Geography",
        "Gender",
        "Age",
        "AgeBand",
        "Tenure",
        "ContractType",
        "Balance",
        "NumOfProducts",
        "HasCrCard",
        "IsActiveMember",
        "EstimatedSalary",
        "PaymentMethod",
        "MonthlyCharges",
        "AnnualRevenueAtRisk",
        "ChurnStatus",
        "Exited",
    ]
    df[columns].to_csv(POWERBI_DIR / "customer_churn_powerbi_easy_mode.csv", index=False)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    df = add_business_fields(pd.read_csv(SOURCE_CSV))

    churn_distribution(df)
    churn_by_geography(df)
    churn_by_contract(df)
    churn_by_age_band(df)
    credit_score_balance_scatter(df)
    revenue_at_risk(df)
    export_powerbi_dataset(df)

    print(f"Generated Python chart images in {OUTPUT_DIR}")
    print(f"Generated Power BI import CSV in {POWERBI_DIR}")


if __name__ == "__main__":
    main()
