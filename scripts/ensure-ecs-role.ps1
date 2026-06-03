# Create ecsTaskExecutionRole if missing (required for Fargate).
$ErrorActionPreference = "Stop"
$RoleName = "ecsTaskExecutionRole"

$ErrorActionPreference = "Continue"
aws iam get-role --role-name $RoleName 2>$null | Out-Null
$roleExists = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = "Stop"

if ($roleExists) {
    Write-Host "Role $RoleName already exists."
    exit 0
}

Write-Host "Creating $RoleName..."
$Trust = @'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ecs-tasks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
'@
$TrustPath = Join-Path $env:TEMP "ecs-trust.json"
[System.IO.File]::WriteAllText($TrustPath, $Trust)
$TrustFile = "file://" + ($TrustPath -replace '\\', '/')
aws iam create-role --role-name $RoleName --assume-role-policy-document $TrustFile
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to create role." }
aws iam attach-role-policy --role-name $RoleName --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
Write-Host "Done. Run deploy-ecs.ps1 next."
