import pandas as pd
from sqlalchemy import create_engine

df = pd.read_parquet(
    "data/cleaned_taxi.parquet"
)

engine = create_engine(
    "sqlite:///taxi.db"
)

df.to_sql(
    "trips",
    engine,
    if_exists="replace",
    index=False,
    chunksize=50000
)

print("Database loaded")