# Build and push Docker image to ECR.
# Usage: .\scripts\push-ecr.ps1
# Requires: AWS CLI, Docker Desktop, $env:AWS_REGION (default us-east-2)

$ErrorActionPreference = "Stop"
$Region = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-2" }
$Repo = "nyc-taxi-dashboard"

$AccountId = (aws sts get-caller-identity --query Account --output text).Trim()
$Registry = "$AccountId.dkr.ecr.$Region.amazonaws.com"
$ImageUri = "$Registry/${Repo}:latest"

Set-Location (Join-Path $PSScriptRoot "..")

Write-Host "==> Ensuring ECR repository..."
$ErrorActionPreference = "Continue"
aws ecr describe-repositories --repository-names $Repo --region $Region 2>$null | Out-Null
$repoExists = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = "Stop"
if (-not $repoExists) {
    aws ecr create-repository --repository-name $Repo --region $Region | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Error "Failed to create ECR repository." }
}

Write-Host "==> Logging in to ECR..."
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $Registry
if ($LASTEXITCODE -ne 0) { Write-Error "ECR login failed." }

Write-Host "==> Building image..."
docker build -t $Repo .
if ($LASTEXITCODE -ne 0) { Write-Error "Docker build failed." }

Write-Host "==> Pushing image..."
docker tag "${Repo}:latest" $ImageUri
docker push $ImageUri
if ($LASTEXITCODE -ne 0) { Write-Error "Docker push failed." }

Write-Host ""
Write-Host "Pushed: $ImageUri"
Write-Host "Set for deploy: `$env:IMAGE_URI = '$ImageUri'"
