import sys
from pathlib import Path

import pandas as pd
from flask import Flask, jsonify

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from db import get_engine

app = Flask(__name__)
engine = get_engine()


@app.route("/api/summary")
def summary():
    query = """
    SELECT
        COUNT(*) AS trips,
        AVG(fare_amount) AS avg_fare,
        AVG(tip_amount) AS avg_tip,
        AVG(trip_distance) AS avg_distance
    FROM trips
    """

    result = pd.read_sql(query, engine)

    return jsonify(result.to_dict(orient="records")[0])


@app.route("/api/trips-by-hour")
def trips_by_hour():
    query = """
    SELECT
        hour,
        COUNT(*) AS trip_count
    FROM trips
    GROUP BY hour
    ORDER BY hour
    """

    result = pd.read_sql(query, engine)

    return jsonify(result.to_dict(orient="records"))


if __name__ == "__main__":
    app.run(debug=True)
