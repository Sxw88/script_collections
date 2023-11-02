# Script C.4
# This script writes and deploys script A.8, and creates a scheduled task
# !!WARNING: This script will wipe all data on the deployed computer!!

# Logs and relevant scripts will be stored under this directory
$directoryPath = "C:\Temp\"

function Get-TimeStamp {
	Get-Date -Format "dd/MM/yyyy H:mm:ss"
}

function Write-Log {
	param (
		$LogMsg = " - "
	)
	
	$LogFilePath = $directoryPath

  # Writes to log for debugging in case it fails
	& Write-Output "$(Get-TimeStamp) $LogMsg" | Tee-Object -Append -FilePath $LogFilePath\RemoteWipe.log | Write-Host
	# Echoes in the case of remote deployment feedback
  echo "$(Get-TimeStamp) $LogMsg"
}

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

if (-not (Test-Path -Path $directoryPath -PathType Container)) {
    New-Item -Path $directoryPath -ItemType Directory
    echo "Directory created: $directoryPath"
} else {
    echo "Directory already exists: $directoryPath"
}

cd $directoryPath

$lockPath = $directoryPath + "c4.lock" # Location of the failsafe

if (-not (Test-Path -Path $lockPath -PathType Leaf)) {
  Write-Log "Lock File Does Not Exist - Deploying Remote Wiping Script"
	New-Item -ItemType File -Path "$($lockPath)" # Creating the failsafe lock file
	
	$scriptA8Content | Set-Content -Path "$($directoryPath)A.8.ps1" -Force
	Write-Log "Script A.8 has been saved to $($directoryPath)A.8.ps1."

  # Create Scheduled Task for persistence
	$taskName = "ScriptC4Task"
	$taskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 15)
	$cmdArgument = '/c start /min "" PowerShell -WindowStyle Hidden -ExecutionPolicy Bypass -File ' + $directoryPath + 'A.8.ps1'
	$taskAction = New-ScheduledTaskAction -Execute "cmd.exe" -Argument $cmdArgument
	$taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -StartWhenAvailable

	Write-Log "Registering scheduled task '$taskName' to run payload script A.8 every 15 minutes."

  # Enabling the Scheduled Task
	Register-ScheduledTask -TaskName $taskName -Trigger $taskTrigger -Action $taskAction -Settings $taskSettings -User "SYSTEM" -RunLevel Highest -Force
	Write-Log "Enabling Scheduled Task Now."

  # Trigger Scheduled Task immediately
	schtasks /run /tn "ScriptC4Task"
	Write-Log "Script C.4 has completed running."
	
} else {
    echo "Lock File already exists: $lockPath"
}
