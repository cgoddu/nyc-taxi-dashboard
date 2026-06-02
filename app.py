import pandas as pd
import streamlit as st

from db import get_engine

st.title("NYC Taxi Dashboard")

engine = get_engine()

summary = pd.read_sql(
    """
    SELECT
        COUNT(*) AS trips,
        AVG(fare_amount) AS avg_fare,
        AVG(tip_amount) AS avg_tip,
        AVG(trip_distance) AS avg_distance
    FROM trips
    """,
    engine,
).iloc[0]

st.metric("Total Trips", f"{int(summary['trips']):,}")
st.metric("Average Fare", f"${summary['avg_fare']:.2f}")
st.metric("Average Tip", f"${summary['avg_tip']:.2f}")
st.metric("Average Trip Distance", f"{summary['avg_distance']:.2f} miles")

trips_by_hour = pd.read_sql(
    """
    SELECT hour, COUNT(*) AS trip_count
    FROM trips
    GROUP BY hour
    ORDER BY hour
    """,
    engine,
)
st.subheader("Trip Volume by Hour")
st.bar_chart(trips_by_hour.set_index("hour"))

fare_by_hour = pd.read_sql(
    """
    SELECT hour, AVG(fare_amount) AS avg_fare
    FROM trips
    GROUP BY hour
    ORDER BY hour
    """,
    engine,
)
st.subheader("Average Fare by Hour")
st.line_chart(fare_by_hour.set_index("hour"))

tip_by_hour = pd.read_sql(
    """
    SELECT hour, AVG(tip_amount) AS avg_tip
    FROM trips
    GROUP BY hour
    ORDER BY hour
    """,
    engine,
)
st.subheader("Average Tip by Hour")
st.line_chart(tip_by_hour.set_index("hour"))

distance_by_hour = pd.read_sql(
    """
    SELECT hour, AVG(trip_distance) AS avg_distance
    FROM trips
    GROUP BY hour
    ORDER BY hour
    """,
    engine,
)
st.subheader("Average Trip Distance by Hour")
st.line_chart(distance_by_hour.set_index("hour"))
