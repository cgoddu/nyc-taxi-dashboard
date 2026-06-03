# Print public IP for the running ECS task (Streamlit on port 8501).
$ErrorActionPreference = "Stop"
$Region = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-2" }
$Cluster = "taxi-cluster"
$Service = "taxi-dashboard"

$TaskArn = (aws ecs list-tasks --cluster $Cluster --service-name $Service --region $Region --query "taskArns[0]" --output text).Trim()
if (-not $TaskArn -or $TaskArn -eq "None") {
    Write-Error "No running task. Wait for service to start or check ECS console."
}

$TaskJson = aws ecs describe-tasks --cluster $Cluster --tasks $TaskArn --region $Region --output json | ConvertFrom-Json
$Eni = $null
foreach ($d in $TaskJson.tasks[0].attachments[0].details) {
    if ($d.name -eq "networkInterfaceId") { $Eni = $d.value; break }
}
if (-not $Eni) { Write-Error "Could not find network interface for task." }

$PublicIp = (aws ec2 describe-network-interfaces --network-interface-ids $Eni --region $Region `
    --query "NetworkInterfaces[0].Association.PublicIp" --output text).Trim()

Write-Host "Dashboard: http://${PublicIp}:8501"
