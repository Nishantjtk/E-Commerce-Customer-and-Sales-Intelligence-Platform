"""Profile raw source quality without altering PostgreSQL source tables."""
from __future__ import annotations

import pandas as pd

from common import OUTPUT_DIR, ensure_output_directories, get_engine, query_frame

TABLES = [
    "customers", "orders", "order_items", "products", "sellers",
    "order_payments", "order_reviews", "geolocation", "category_translation",
]


def main() -> None:
    engine = get_engine()
    records: list[dict[str, object]] = []
    for table in TABLES:
        columns = query_frame(
            f"SELECT column_name FROM information_schema.columns "
            f"WHERE table_schema = 'raw' AND table_name = '{table}' ORDER BY ordinal_position", engine
        )["column_name"].tolist()
        null_expression = " + ".join(f"CASE WHEN {column} IS NULL THEN 1 ELSE 0 END" for column in columns)
        profile = query_frame(
            f"SELECT COUNT(*) AS row_count, COALESCE(SUM({null_expression}), 0) AS null_cell_count "
            f"FROM raw.{table}", engine
        ).iloc[0].to_dict()
        records.append({"table_name": f"raw.{table}", **profile})

    ensure_output_directories()
    report = pd.DataFrame(records)
    report["null_cell_rate"] = report["null_cell_count"] / report["row_count"].clip(lower=1)
    path = OUTPUT_DIR / "data_quality_profile.csv"
    report.to_csv(path, index=False)
    print(f"Wrote {path}")


if __name__ == "__main__":
    main()
