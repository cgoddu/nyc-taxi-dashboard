import sys
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from db import get_engine

df = pd.read_parquet(ROOT / "data" / "cleaned_taxi.parquet")

engine = get_engine()

df.to_sql(
    "trips",
    engine,
    if_exists="replace",
    index=False,
    chunksize=50000,
)

print(f"Loaded {len(df):,} trips into PostgreSQL")
