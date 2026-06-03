# Create ecsTaskExecutionRole if missing (required for Fargate).
$ErrorActionPreference = "Stop"
$RoleName = "ecsTaskExecutionRole"

aws iam get-role --role-name $RoleName 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
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
$Trust | Set-Content (Join-Path $env:TEMP "ecs-trust.json") -Encoding UTF8
aws iam create-role --role-name $RoleName --assume-role-policy-document "file://$($env:TEMP -replace '\\','/')/ecs-trust.json"
aws iam attach-role-policy --role-name $RoleName --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
Write-Host "Done. Run deploy-ecs.ps1 again."
