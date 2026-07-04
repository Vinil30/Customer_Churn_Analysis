# Python Visualizations

Run this script from the repository root:

```bash
python visualizations/python/generate_visualizations.py
```

It reads the unchanged source dataset at `data/Churn_Modelling.csv` and creates PNG charts in `visualizations/python/outputs/`.

Generated visuals:

- Churn distribution
- Churn rate by geography
- Churn rate by derived contract type
- Retained vs churned mix by age band
- Credit score vs balance by churn outcome
- Revenue-at-risk segments

These charts are for analytics and portfolio reporting only. They do not change the ANN training or prediction workflow.
