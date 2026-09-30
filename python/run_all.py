"""Run the certified Python analytics sequence from the project root."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

SCRIPTS = [
    "01_data_cleaning.py", "02_data_validation.py", "03_eda.py",
    "04_rfm_analysis.py", "05_cohort_analysis.py", "06_customer_experience_analysis.py",
]


def main() -> None:
    script_directory = Path(__file__).parent
    for script in SCRIPTS:
        print(f"Running {script}")
        subprocess.run([sys.executable, str(script_directory / script)], check=True)


if __name__ == "__main__":
    main()
