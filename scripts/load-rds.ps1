# One-off: load parquet into Aurora (run from your PC; needs Docker + network path to RDS).
# Usage:
#   $env:DATABASE_URL = "postgresql+psycopg2://postgres:PASSWORD@endpoint:5432/taxi"
#   .\scripts\load-rds.ps1

$ErrorActionPreference = "Stop"
if (-not $env:DATABASE_URL) {
    Write-Error "Set DATABASE_URL to your Aurora connection string."
}

Set-Location (Join-Path $PSScriptRoot "..")
docker build -t nyc-taxi-app .
docker run --rm -e DATABASE_URL="$env:DATABASE_URL" nyc-taxi-app python scripts/load_database.py
Write-Host "Done. trips table should be in Aurora."
