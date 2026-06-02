#!/bin/sh
set -e

echo "Loading trips table into PostgreSQL..."
python scripts/load_database.py

exec streamlit run app.py --server.address=0.0.0.0
