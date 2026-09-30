# Python Analytics

The deliverables are scripts so that they run consistently from the command line, can be scheduled, and do not depend on hidden notebook state. They query the certified PostgreSQL `raw` and `analytics` objects; they do not write to the database.

| Script | Output |
| --- | --- |
| `01_data_cleaning.py` | Raw-table volume and null-cell profile |
| `02_data_validation.py` | The certified SQL exception-count report |
| `03_eda.py` | Monthly sales and delivery/satisfaction extracts and figures |
| `04_rfm_analysis.py` | RFM customer export, segment summary, and chart |
| `05_cohort_analysis.py` | Cohort long-form data, retention matrix, and heatmap |
| `06_customer_experience_analysis.py` | Category delivery/satisfaction analysis and risk chart |
| `run_all.py` | Runs the six scripts in order |

## Local execution

From the project root in PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
$env:ECOMMERCE_DB_URL = 'postgresql+psycopg://postgres:<YOUR_PASSWORD>@localhost:5433/ecommerce_intelligence'
python python\run_all.py
```

Use a real password only in your local shell; do not commit it. Every generated CSV and PNG is written to `output/` and `output/figures/`. Run individual scripts with `python python\04_rfm_analysis.py`, for example.

Forecasting remains intentionally out of scope until baseline analysis demonstrates decision value and an appropriate validation horizon is agreed.
