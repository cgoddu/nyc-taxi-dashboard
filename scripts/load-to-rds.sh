#!/bin/sh
# Load parquet into RDS. Set DATABASE_URL first (see .env.example).
set -e

cd "$(dirname "$0")/.."

if [ -z "$DATABASE_URL" ]; then
  echo "Set DATABASE_URL to your RDS connection string, then run again."
  echo "Example:"
  echo '  export DATABASE_URL="postgresql+psycopg2://postgres:YOUR_PASSWORD@your-db.xxxxx.us-east-1.rds.amazonaws.com:5432/taxi"'
  exit 1
fi

docker build -t nyc-taxi-app .
docker run --rm -e DATABASE_URL="$DATABASE_URL" nyc-taxi-app python scripts/load_database.py
echo "Data loaded into RDS."
