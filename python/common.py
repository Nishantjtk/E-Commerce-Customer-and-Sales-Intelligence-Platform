"""Shared configuration and database helpers for reproducible analytics scripts."""
from __future__ import annotations

import os
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine

PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = PROJECT_ROOT / "output"
FIGURE_DIR = OUTPUT_DIR / "figures"


def get_engine() -> Engine:
    """Create an engine from ECOMMERCE_DB_URL; never embed credentials in code."""
    url = os.getenv("ECOMMERCE_DB_URL")
    if not url:
        raise RuntimeError(
            "Set ECOMMERCE_DB_URL, e.g. "
            "postgresql+psycopg://postgres:<password>@localhost:5433/ecommerce_intelligence"
        )
    return create_engine(url, pool_pre_ping=True)


def query_frame(sql: str, engine: Engine | None = None) -> pd.DataFrame:
    """Run a read-only SELECT statement and return a DataFrame."""
    active_engine = engine or get_engine()
    return pd.read_sql_query(sql, active_engine)


def ensure_output_directories() -> None:
    OUTPUT_DIR.mkdir(exist_ok=True)
    FIGURE_DIR.mkdir(parents=True, exist_ok=True)


def save_figure(figure, filename: str) -> Path:
    """Save a consistently styled PNG in output/figures."""
    ensure_output_directories()
    path = FIGURE_DIR / filename
    figure.savefig(path, dpi=160, bbox_inches="tight")
    return path
