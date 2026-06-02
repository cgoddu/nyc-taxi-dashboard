import pandas as pd
import streamlit as st

from db import get_engine

st.title("NYC Taxi Dashboard")

df = pd.read_parquet("data/cleaned_taxi.parquet")
engine = get_engine()



#Summary
st.metric(
    "Total Trips",
    f"{len(df):,}"
)
st.metric(
    "Average Fare",
    f"${df['fare_amount'].mean():.2f}"
)
st.metric(
    "Average Tip",
    f"${df['tip_amount'].mean():.2f}"
)
st.metric(
    "Average Trip Distance",
    f"{df['trip_distance'].mean():.2f} miles"
)

#Aggregate
#TripsByHour
trips_by_hour = (
    df.groupby("hour")
      .size()
      .reset_index(name="trip_count")
)
st.subheader("Trip Volume by Hour")
st.bar_chart(
    trips_by_hour.set_index("hour")
)
# SQL
query = """
SELECT
    hour,
    COUNT(*) AS trip_count
FROM trips
GROUP BY hour
ORDER BY hour
"""
try:
    sql_trips = pd.read_sql(query, engine)
    st.subheader("Trip Volume by Hour (SQL)")
    st.bar_chart(sql_trips.set_index("hour"))
except Exception as e:
    st.warning(f"SQL chart unavailable: {e}")

#FareByHour
fare_by_hour = (
    df.groupby("hour")["fare_amount"]
      .mean()
)
st.subheader("Average Fare by Hour")
st.line_chart(fare_by_hour)
query = """
SELECT
    hour,
    AVG(fare_amount) avg_fare
FROM trips
GROUP BY hour
ORDER BY hour
"""
try:
    sql_result = pd.read_sql(query, engine)
    st.subheader("Average Fare by Hour (SQL)")
    st.line_chart(sql_result.set_index("hour"))
except Exception as e:
    st.warning(f"SQL chart unavailable: {e}")

#TipByHour
tip_by_hour = (
    df.groupby("hour")["tip_amount"]
      .mean()
)
st.subheader("Average Tip by Hour")
st.line_chart(tip_by_hour)

#DistByHour
distance_by_hour = (
    df.groupby("hour")["trip_distance"]
      .mean()
)
st.subheader("Average Trip Distance by Hour")
st.line_chart(distance_by_hour)