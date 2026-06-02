import pandas as pd

# Data cleaning pipeline
df = pd.read_parquet(
    "data/yellow_tripdata_2026-01.parquet"
).head(100000)

# Remove bad records
df = df[df["trip_distance"] > 0]
df = df[df["fare_amount"] > 0]

# Remove crazy outliers
df = df[df["trip_distance"] < 100]
df = df[df["fare_amount"] < 500]

# Feature engineering - Create hour column
df["hour"] = df["tpep_pickup_datetime"].dt.hour

df.to_parquet(
    "data/cleaned_taxi.parquet",
    index=False
)

print(f"Processed {len(df):,} trips")