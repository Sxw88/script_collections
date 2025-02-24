# This script removes Progressive Web Apps by Chrome & Edge

# Usage: deploy script with admin privileges, it will:
# 1. Iterate through all user profiles
# 2. Remove registry keys under CurrentVersion\Uninstall associated with PWAs
# 3. Check Desktop folder and delete shortcuts associated with PWAs

# Q&A:
# Q - Why not use uninstall string?
# A - As of 2025, there is an unskippable prompt - even when running as admin
# Q - Where log?
# A - C:\Temp\ChromeApp-*.log


# Generate a timestamped log file
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LogFile = "C:\Temp\ChromeApp-$Timestamp.log"

# Ensure the log directory exists
$LogDir = "C:\Temp"
if (!(Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
}

# Function to log messages
function Write-Log {
    param ([string]$Message)
    $LogEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Add-Content -Path $LogFile -Value $LogEntry
    Write-Output $LogEntry
}

Write-Log "Starting Chrome App full removal script."

# Get all user profiles (excluding system profiles)
$UserProfiles = Get-WmiObject Win32_UserProfile | Where-Object { $_.Special -eq $false }

foreach ($User in $UserProfiles) {
    $UserProfilePath = $User.LocalPath
    $UserSID = $User.SID
    $UserName = Split-Path -Leaf $UserProfilePath
    Write-Log "Processing user: $UserName (SID: $UserSID)"

    # STEP 1 - Iterate through the Registry list of installed applications
	$registryPath = "Registry::HKEY_USERS\" + $UserSID + "\Software\Microsoft\Windows\CurrentVersion\Uninstall"
	# Get all subkeys under the specified registry path
	$subkeys = Get-ChildItem -Path $registryPath
	
	foreach ($subkey in $subkeys) {
		# Retrieve values of 'Publisher' and 'UninstallString'
		$displayName = Get-ItemProperty -Path $subkey.PSPath -Name "DisplayName" -ErrorAction SilentlyContinue
		$publisher = Get-ItemProperty -Path $subkey.PSPath -Name "Publisher" -ErrorAction SilentlyContinue
		$uninstallString = Get-ItemProperty -Path $subkey.PSPath -Name "UninstallString" -ErrorAction SilentlyContinue

		# Check if the value is null or empty
		if (-not $displayName -or -not $displayName.DisplayName) {
			$displayName = "DisplayName not found"
		}

		# Filter Publisher and UninstallString key datas to search for PWAs
		if ($publisher -and $uninstallString) {
			if ($publisher.Publisher -eq "Google\Chrome" -and $uninstallString.UninstallString -match "--uninstall-app-id") {
				Write-Log "Found matching key for $($displayName.DisplayName) at $($subkey.PSPath)"
				
				Remove-Item -Path $subkey.PSPath -Recurse -Force
                Write-Log "Deleted $($displayName.DisplayName) at $($subkey.PSPath)"
			}
		}
	}
	
	# STEP 2 - Iterate through Desktop and clean up application shortcuts
	$desktopPath = "C:\Users\$UserName\Desktop"
	Write-Log "Checking Desktop of $UserName at $desktopPath"
	
	# Get all .lnk files in the Desktop folder
	$shortcuts = Get-ChildItem -Path $desktopPath -Filter "*.lnk" -File -ErrorAction SilentlyContinue
	
	foreach ($shortcut in $shortcuts) {
		
		# Use WScript.Shell to resolve the shortcut target
		$shell = New-Object -ComObject WScript.Shell
		$shortcutPath = $shortcut.FullName
		$shortcutObject = $shell.CreateShortcut($shortcutPath)
		$shortcutArgs = $shortcutObject.Arguments.Trim()
		
		# Check if the shortcut's target contains "--app-id="
		if ($shortcutArgs -match "--app-id=") {
			Write-Log "Found matching shortcut $shortcut at $shortcutPath"
			
			# Remove the shortcut
			Remove-Item -Path $shortcutPath -Force
			Write-Log "Deleted $shortcut at $shortcutPath"
		} elseif ($shortcutArgs -match "--app-launch-source=") {
			Write-Log "Found matching shortcut $shortcut at $shortcutPath"
			
			# Remove the shortcut
			Remove-Item -Path $shortcutPath -Force
			Write-Log "Deleted $shortcut at $shortcutPath"
		}
	}
}

Write-Log "Chrome App full removal script completed."
