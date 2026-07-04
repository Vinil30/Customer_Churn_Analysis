# Power BI Easy Mode Dashboard

Use `customer_churn_powerbi_easy_mode.csv` as a simple flat import table for Power BI Desktop.

## Build Steps

1. Open Power BI Desktop.
2. Select **Get Data > Text/CSV**.
3. Import `visualizations/powerbi/customer_churn_powerbi_easy_mode.csv`.
4. Name the table `CustomerChurn`.
5. Add the measures from `measures.dax`.
6. Create one dashboard page named `Churn Executive Overview`.

## Recommended Visuals

- Cards: `Total Customers`, `Churned Customers`, `Churn Rate %`, `Annual Revenue At Risk`
- Clustered bar chart: `Churn Rate %` by `Geography`
- Clustered bar chart: `Churn Rate %` by `ContractType`
- Matrix: `PaymentMethod`, `ContractType`, `Total Customers`, `Churn Rate %`, `Annual Revenue At Risk`
- Stacked column chart: `ChurnStatus` by `AgeBand`
- Slicer: `Geography`
- Slicer: `ContractType`
- Slicer: `PaymentMethod`

This is intentionally easy mode: one import table, simple measures, and no relationship setup required.
