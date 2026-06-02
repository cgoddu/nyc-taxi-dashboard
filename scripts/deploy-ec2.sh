#!/bin/sh
# One-command deploy for EC2 (no docker-compose required).
set -e

cd "$(dirname "$0")/.."

echo "==> Starting Postgres..."
docker network create taxi-net 2>/dev/null || true
docker stop taxi-postgres nyc-taxi-app 2>/dev/null || true
docker rm taxi-postgres nyc-taxi-app 2>/dev/null || true

docker run -d --name taxi-postgres --network taxi-net \
  -e POSTGRES_DB=taxi \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  postgres:17

echo "==> Waiting for Postgres..."
sleep 20

echo "==> Building app..."
docker build -t nyc-taxi-app .

echo "==> Loading data..."
docker run --rm --network taxi-net \
  -e DATABASE_URL=postgresql+psycopg2://postgres:postgres@taxi-postgres:5432/taxi \
  nyc-taxi-app python scripts/load_database.py

echo "==> Starting dashboard..."
docker run -d --name nyc-taxi-app --network taxi-net \
  -p 8501:8501 \
  -e DATABASE_URL=postgresql+psycopg2://postgres:postgres@taxi-postgres:5432/taxi \
  nyc-taxi-app

echo ""
echo "Done. Open http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo YOUR-EC2-IP):8501"
