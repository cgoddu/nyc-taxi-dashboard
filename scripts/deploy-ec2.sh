#!/bin/sh
# Single-container Streamlit deploy. Requires DATABASE_URL (RDS).
set -e

cd "$(dirname "$0")/.."

if [ -z "$DATABASE_URL" ]; then
  echo "Set DATABASE_URL to your RDS connection string, then run again."
  echo '  export DATABASE_URL="postgresql+psycopg2://postgres:PASSWORD@your-rds-host:5432/taxi"'
  exit 1
fi

echo "==> Building app..."
docker build -t nyc-taxi-app .

echo "==> Starting dashboard..."
docker stop nyc-taxi-app 2>/dev/null || true
docker rm nyc-taxi-app 2>/dev/null || true

docker run -d --name nyc-taxi-app -p 8501:8501 \
  -e DATABASE_URL="$DATABASE_URL" \
  nyc-taxi-app

IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "YOUR-EC2-IP")
echo ""
echo "Done. Open http://${IP}:8501"
