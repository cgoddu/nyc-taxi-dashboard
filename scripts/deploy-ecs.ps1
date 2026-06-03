# Deploy Streamlit to ECS Fargate (replaces EC2).
# Prereqs: Aurora taxi-db with self-managed password, data loaded, security groups wired.
#
# Usage:
#   $env:AWS_REGION = "us-east-2"
#   $env:DATABASE_URL = "postgresql+psycopg2://postgres:PASSWORD@ENDPOINT:5432/taxi"
#   .\scripts\push-ecr.ps1
#   $env:IMAGE_URI = "<uri printed by push-ecr>"
#   .\scripts\deploy-ecs.ps1

$ErrorActionPreference = "Stop"
$Region = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-2" }
$Cluster = "taxi-cluster"
$Service = "taxi-dashboard"
$Family = "nyc-taxi-dashboard"
$LogGroup = "/ecs/nyc-taxi-dashboard"

if (-not $env:DATABASE_URL) {
    Write-Error "Set DATABASE_URL first. Example: `$env:DATABASE_URL = 'postgresql+psycopg2://postgres:PASS@host:5432/taxi'"
}
if (-not $env:IMAGE_URI) {
    Write-Error "Set IMAGE_URI from push-ecr.ps1 output, or run push-ecr.ps1 first."
}

$AccountId = (aws sts get-caller-identity --query Account --output text).Trim()
$Root = Join-Path $PSScriptRoot ".."
Set-Location $Root

Write-Host "==> Checking ecsTaskExecutionRole..."
aws iam get-role --role-name ecsTaskExecutionRole 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Run: .\scripts\ensure-ecs-role.ps1"
    Write-Error "ecsTaskExecutionRole missing."
}

Write-Host "==> Ensuring CloudWatch log group..."
aws logs create-log-group --log-group-name $LogGroup --region $Region 2>$null

Write-Host "==> Ensuring ECS cluster..."
$ClusterStatus = (aws ecs describe-clusters --clusters $Cluster --region $Region --query "clusters[0].status" --output text 2>$null).Trim()
if ($ClusterStatus -ne "ACTIVE") {
    aws ecs create-cluster --cluster-name $Cluster --region $Region | Out-Null
}

Write-Host "==> Registering task definition..."
$TaskDefPath = Join-Path $Root "ecs\task-definition.json"
$TaskJson = Get-Content $TaskDefPath -Raw
$TaskJson = $TaskJson.Replace("ACCOUNT_ID", $AccountId)
$TaskJson = $TaskJson.Replace("IMAGE_URI", $env:IMAGE_URI)
$TaskJson = $TaskJson.Replace("DATABASE_URL_VALUE", $env:DATABASE_URL)
$TaskJson = $TaskJson.Replace("AWS_REGION", $Region)
$TempTask = Join-Path $env:TEMP "nyc-taxi-task-def.json"
$TaskJson | Set-Content $TempTask -Encoding UTF8
aws ecs register-task-definition --cli-input-json "file://$($TempTask -replace '\\','/')" --region $Region | Out-Null

Write-Host "==> Finding default VPC subnets..."
$Subnets = (aws ec2 describe-subnets --region $Region --filters "Name=default-for-az,Values=true" --query "Subnets[*].SubnetId" --output text).Trim() -split "\s+"
if ($Subnets.Count -lt 1) { Write-Error "No default subnets found." }

Write-Host "==> Ensuring security group for ECS tasks..."
$VpcId = (aws ec2 describe-subnets --subnet-ids $Subnets[0] --region $Region --query "Subnets[0].VpcId" --output text).Trim()
$SgName = "ecs-taxi-dashboard-sg"
$SgId = (aws ec2 describe-security-groups --region $Region --filters "Name=group-name,Values=$SgName" "Name=vpc-id,Values=$VpcId" --query "SecurityGroups[0].GroupId" --output text 2>$null).Trim()
if (-not $SgId -or $SgId -eq "None") {
    $SgId = (aws ec2 create-security-group --group-name $SgName --description "ECS taxi dashboard" --vpc-id $VpcId --region $Region --query GroupId --output text).Trim()
    aws ec2 authorize-security-group-ingress --group-id $SgId --protocol tcp --port 8501 --cidr 0.0.0.0/0 --region $Region 2>$null
    Write-Host "Created SG $SgId (port 8501 open). Add inbound 5432 on Aurora SG from this SG."
}

$SubnetCsv = ($Subnets -join ",")
$NetworkConfig = "awsvpcConfiguration={subnets=[$SubnetCsv],securityGroups=[$SgId],assignPublicIp=ENABLED}"

$Existing = (aws ecs describe-services --cluster $Cluster --services $Service --region $Region --query "services[?serviceName=='$Service'].status" --output text 2>$null).Trim()

if ($Existing -eq "ACTIVE") {
    Write-Host "==> Updating ECS service..."
    aws ecs update-service --cluster $Cluster --service $Service --task-definition $Family --force-new-deployment --region $Region | Out-Null
} else {
    Write-Host "==> Creating ECS service..."
    aws ecs create-service --cluster $Cluster --service-name $Service --task-definition $Family `
        --desired-count 1 --launch-type FARGATE --network-configuration $NetworkConfig --region $Region | Out-Null
}

Write-Host ""
Write-Host "Deploy started. Wait 2-3 min, then get the public IP:"
Write-Host "  aws ecs list-tasks --cluster $Cluster --service-name $Service --region $Region"
Write-Host "  aws ecs describe-tasks --cluster $Cluster --tasks <task-arn> --region $Region --query 'tasks[0].attachments[0].details'"
Write-Host ""
Write-Host "Or: ECS Console -> Clusters -> $Cluster -> $Service -> task -> public IP -> http://IP:8501"
Write-Host ""
Write-Host "Stop EC2 instance when ECS works to avoid double billing."
