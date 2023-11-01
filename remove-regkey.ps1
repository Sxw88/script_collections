# This script iterates through all users on a computer under "HKEY_USERS"
# and removes a specified registry key settings

# For demonstration purposes this script will remove the "AutoConfigURL" key for each users 
# at the following path: Registry::\HKEY_USERS\<SID>\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings
# To test this script you may create a registry key first ^^

# A log file can be found at C:\Temp\remove-regkey.log after running this script
$LogFilePath = "C:\Temp\"

# Specify the path to the registry key you want to check --> Registry::\HKEY_USERS\$keyPath
$keyPath 	= "SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"
$valueName 	= "AutoConfigURL" 	# Key value name


function Get-TimeStamp {
	Get-Date -Format "dd/MM/yyyy H:mm:ss"
}

function Write-Log {
	param (
		$LogMsg = " - "
	)
	
	$logPath = $LogFilePath
	
	& Write-Output "$(Get-TimeStamp) $LogMsg" | Tee-Object -Append -FilePath $logPath\remove-regkey.log | Write-Host
}

if (-not (Test-Path -Path $LogFilePath -PathType Container)) {
    New-Item -Path $LogFilePath -ItemType Directory
    echo "Directory created: $LogFilePath"
} else {
    echo "Directory already exists: $LogFilePath"
}

# Define the path to the Registry key you want to check
$registryPath = 'Registry::HKEY_USERS\'

# Get all user profiles in the Registry
$profileSIDs = Get-ChildItem $registryPath 

Write-Log "List of User SIDs: `n$($profileSIDs)"

# Loop through user profiles and check if the key exists
foreach ($SID in $profileSIDs) {
	
    Write-Log "Checking for User SID $($SID)"
    Write-Log "Checking Path $($userRegistryPath)"
    
    # Concatenate strings to make the full path to the key
    $userRegistryPath 	= "Registry::$($SID)\$($keyPath)"
    
    if (Test-Path -Path $userRegistryPath) {
        Write-Log "Path exists for user: $($SID.PSChildName)"
        
        $value = Get-ItemProperty -Path $userRegistryPath -Name $valueName -ErrorAction SilentlyContinue
         
        if ($value -ne $null) {
        	Write-Log "Key $($valueName) exists for user: $($SID.PSChildName) - Removing key now ...`n"
       		Remove-ItemProperty -Path $userRegistryPath -Name $valueName
    	}
    }
}
