# Create a simple RDS PostgreSQL instance with a password YOU choose (not Aurora Express).
# Usage:
#   $env:AWS_REGION = "us-east-2"
#   $env:DB_PASSWORD = "YourStrongPassword123!"
#   .\scripts\create-rds-postgres.ps1
#
# After status is "available", use the endpoint in DATABASE_URL and run load-rds.ps1

$ErrorActionPreference = "Stop"
$Region = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-2" }
$DbId = "taxi-postgres"
$DbName = "taxi"
$User = "postgres"
$Password = $env:DB_PASSWORD

if (-not $Password) {
    Write-Error "Set a password first: `$env:DB_PASSWORD = 'YourStrongPassword123!'"
}

$Existing = (aws rds describe-db-instances --db-instance-identifier $DbId --region $Region --query "DBInstances[0].DBInstanceStatus" --output text 2>$null).Trim()
if ($Existing -and $Existing -ne "None") {
    $Endpoint = (aws rds describe-db-instances --db-instance-identifier $DbId --region $Region --query "DBInstances[0].Endpoint.Address" --output text).Trim()
    Write-Host "Instance $DbId already exists (status: $Existing)."
    Write-Host "Endpoint: $Endpoint"
    Write-Host "DATABASE_URL=postgresql+psycopg2://${User}:PASSWORD@${Endpoint}:5432/${DbName}"
    exit 0
}

Write-Host "==> Default VPC..."
$VpcId = (aws ec2 describe-vpcs --region $Region --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text).Trim()

Write-Host "==> Security group for RDS..."
$SgName = "taxi-postgres-sg"
$SgId = (aws ec2 describe-security-groups --region $Region --filters "Name=group-name,Values=$SgName" "Name=vpc-id,Values=$VpcId" --query "SecurityGroups[0].GroupId" --output text 2>$null).Trim()
if (-not $SgId -or $SgId -eq "None") {
    $SgId = (aws ec2 create-security-group --group-name $SgName --description "RDS taxi postgres" --vpc-id $VpcId --region $Region --query GroupId --output text).Trim()
    aws ec2 authorize-security-group-ingress --group-id $SgId --protocol tcp --port 5432 --cidr 0.0.0.0/0 --region $Region 2>$null
    Write-Host "Created $SgId (5432 open for setup - restrict later)"
}

Write-Host "==> Creating RDS PostgreSQL (5-10 min)..."
aws rds create-db-instance `
    --db-instance-identifier $DbId `
    --db-instance-class db.t4g.micro `
    --engine postgres `
    --master-username $User `
    --master-user-password $Password `
    --allocated-storage 20 `
    --db-name $DbName `
    --vpc-security-group-ids $SgId `
    --publicly-accessible `
    --backup-retention-period 0 `
    --no-multi-az `
    --region $Region | Out-Null

Write-Host "Waiting for database to become available..."
aws rds wait db-instance-available --db-instance-identifier $DbId --region $Region

$Endpoint = (aws rds describe-db-instances --db-instance-identifier $DbId --region $Region --query "DBInstances[0].Endpoint.Address" --output text).Trim()
Write-Host ""
Write-Host "RDS is ready."
Write-Host "Endpoint: $Endpoint"
Write-Host ""
Write-Host "Set DATABASE_URL with your password, then run:"
Write-Host "  .\scripts\load-rds.ps1"
