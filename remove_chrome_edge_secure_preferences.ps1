# =========================================================
# Enterprise Chrome & Edge Secure Preferences Removal Script
#
# Deployment  : ManageEngine Desktop Central / Endpoint Central
# Log output  : C:\EndpointCentral\Reset-SecurePreferences.log
# 
# Credits to YY
# =========================================================

# -------------------------------------------------------
# Logging Setup
# -------------------------------------------------------

function Get-TimeStamp {
    Get-Date -Format "dd/MM/yyyy H:mm:ss"
}
$RunTimestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss-fff"
function Write-Log {
    param (
        $LogMsg = " - "
    )

    $LogFilePath = "C:\EndpointCentral"

    & Write-Output "$(Get-TimeStamp) $LogMsg" | Tee-Object -Append -FilePath $LogFilePath\Reset-SecurePreferences_$RunTimestamp.log | Write-Host
}

$directoryPath = "C:\EndpointCentral\"

if (-not (Test-Path -Path $directoryPath -PathType Container)) {
    New-Item -Path $directoryPath -ItemType Directory
    Write-Log "Directory created: $directoryPath"
} else {
    Write-Log "Directory already exists: $directoryPath"
}

# -------------------------------------------------------
# Counters
# -------------------------------------------------------

$TotalProfiles    = 0
$TotalSecurePrefs = 0
$TotalDeleted     = 0
$TotalErrors      = 0

$CountChrome      = 0
$CountChromeSxS   = 0
$CountChromeBeta  = 0
$CountChromium    = 0
$CountEdge        = 0

$CountChromeProfiles     = 0
$CountChromeSxSProfiles  = 0
$CountChromeBetaProfiles = 0
$CountChromiumProfiles   = 0
$CountEdgeProfiles       = 0

# -------------------------------------------------------
# Admin Check
# -------------------------------------------------------

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal       = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
$IsAdmin         = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Log "========================================================="
Write-Log "ENTERPRISE CHROME / EDGE SECURE PREFERENCES REMOVAL"
Write-Log "========================================================="
Write-Log "Hostname         : $env:COMPUTERNAME"
Write-Log "Current User     : $env:USERNAME"
Write-Log "Running as Admin : $IsAdmin"

if (-not $IsAdmin) {
    Write-Log "WARNING: Script is NOT running elevated. Some profiles may not be accessible."
}

# # -------------------------------------------------------
# # Terminate Chromium-based browsers
# # -------------------------------------------------------

# Write-Log "========================================================="
# Write-Log "TERMINATING CHROMIUM-BASED BROWSERS"
# Write-Log "========================================================="

# $BrowserProcesses = @(
#     "chrome",
#     "chrome_beta",
#     "chrome_dev",
#     "msedge",
#     "msedge_beta",
#     "chromium"
# )

# foreach ($ProcessName in $BrowserProcesses) {
#     try {
#         $Running = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
#         if ($Running) {
#             $Count = $Running.Count
#             Stop-Process -Name $ProcessName -Force -ErrorAction Stop
#             Write-Log "Terminated $Count x process(es): $ProcessName"
#         } else {
#             Write-Log "Not running: $ProcessName"
#         }
#     }
#     catch {
#         $TotalErrors++
#         Write-Log "ERROR terminating ${ProcessName}: $($_.Exception.Message)"
#     }
# }

# Start-Sleep -Seconds 3
# Write-Log "Browser termination complete."

# -------------------------------------------------------
# Helper: identify browser type from path
# -------------------------------------------------------

function Get-BrowserType {
    param([string]$Path)

    if ($Path -match "\\Google\\Chrome SxS\\")  { return "ChromeSxS"  }
    if ($Path -match "\\Google\\Chrome Beta\\")  { return "ChromeBeta" }
    if ($Path -match "\\Google\\Chrome\\")       { return "Chrome"     }
    if ($Path -match "\\Chromium\\")             { return "Chromium"   }
    if ($Path -match "\\Microsoft\\Edge\\")      { return "Edge"       }

    return "Unknown"
}

# -------------------------------------------------------
# Collect candidate Chrome User Data paths
# across all local fixed drives and all user folders
# -------------------------------------------------------

# Write-Log "========================================================="
# Write-Log "SCANNING FOR CHROME USER DATA PATHS"
# Write-Log "========================================================="

$CandidatePaths = @()

# DriveType 3 = local fixed disk only (excludes network, USB, CD)
$FixedDrives = Get-CimInstance Win32_LogicalDisk | Where-Object {
    $_.DriveType -eq 3
}

foreach ($Drive in $FixedDrives) {

    Write-Log "---------------------------------------------------------"
    Write-Log "Scanning drive: $($Drive.DeviceID + "\")"

    try {

        $DriveRoot = "$($Drive.DeviceID)\"
        $UsersPath = Join-Path $DriveRoot "Users"

        if (Test-Path $UsersPath) {

            $UserFolders = Get-ChildItem $UsersPath `
                                         -Directory `
                                         -Force `
                                         -ErrorAction SilentlyContinue

            foreach ($UserFolder in $UserFolders) {

                $PossibleChromePaths = @(
                    (Join-Path $UserFolder.FullName "AppData\Local\Google\Chrome\User Data"),
                    (Join-Path $UserFolder.FullName "AppData\Local\Google\Chrome SxS\User Data"),
                    (Join-Path $UserFolder.FullName "AppData\Local\Google\Chrome Beta\User Data"),
                    (Join-Path $UserFolder.FullName "AppData\Local\Chromium\User Data"),
                    (Join-Path $UserFolder.FullName "AppData\Local\Microsoft\Edge\User Data")
                )

                foreach ($ChromePath in $PossibleChromePaths) {
                    if (Test-Path $ChromePath) {
                        Write-Log "Found: [$($UserFolder.Name)] $ChromePath"
                        $CandidatePaths += [PSCustomObject]@{
                            User = $UserFolder.Name
                            Path = $ChromePath
                        }
                    }
                }
            }
        }

        # -------------------------------------------------------
        # Fallback: recursive scan if nothing found on this drive
        # -------------------------------------------------------

        $DriveHasResults = $CandidatePaths | Where-Object {
            $_.Path -like "$($Drive.DeviceID + "\")*"
        }

        if ($DriveHasResults.Count -eq 0) {

            Write-Log "No standard paths found on $($Drive.DeviceID). Starting fallback scan..."

            try {

                $FallbackFolders = Get-ChildItem -Path "$($Drive.DeviceID)\" `
                                                 -Directory `
                                                 -Recurse `
                                                 -Force `
                                                 -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.Name -eq "User Data" -and (
                        $_.FullName -match "\\Google\\Chrome\\"      -or
                        $_.FullName -match "\\Google\\Chrome Beta\\" -or
                        $_.FullName -match "\\Chrome SxS\\"          -or
                        $_.FullName -match "\\Chromium\\"            -or
                        $_.FullName -match "\\Microsoft\\Edge\\"       
                    )
                }
 
                foreach ($Folder in $FallbackFolders) {

                    $PathParts    = $Folder.FullName -split "\\"
                    $DetectedUser = "UNKNOWN"

                    if ($PathParts -contains "Users") {
                        $UsersIndex = [Array]::IndexOf($PathParts, "Users")
                        if (($UsersIndex + 1) -lt $PathParts.Count) {
                            $DetectedUser = $PathParts[$UsersIndex + 1]
                        }
                    }

                    Write-Log "Fallback found: [$DetectedUser] $($Folder.FullName)"

                    $CandidatePaths += [PSCustomObject]@{
                        User = $DetectedUser
                        Path = $Folder.FullName
                    }
                }
            }
            catch {
                $TotalErrors++
                Write-Log "ERROR during fallback scan: $($_.Exception.Message)"
            }
        }
    }
    catch {
        $TotalErrors++
        Write-Log "ERROR scanning drive $($Drive.DeviceID): $($_.Exception.Message)"
    }
}

# Remove duplicates
$CandidatePaths = $CandidatePaths | Sort-Object Path -Unique

Write-Log "========================================================="
Write-Log "TOTAL USER DATA PATHS FOUND: $($CandidatePaths.Count)"
Write-Log "========================================================="

# Increment per-browser counters
foreach ($Candidate in $CandidatePaths) {
    switch (Get-BrowserType $Candidate.Path) {
        "Chrome"     { $CountChrome++     }
        "ChromeSxS"  { $CountChromeSxS++  }
        "ChromeBeta" { $CountChromeBeta++  }
        "Chromium"   { $CountChromium++   }
        "Edge"       { $CountEdge++       }
    }
}

# -------------------------------------------------------
# Profile detection and Secure Preferences deletion
# -------------------------------------------------------

Write-Log "========================================================="
Write-Log "SCANNING PROFILES AND DELETING SECURE PREFERENCES"
Write-Log "========================================================="

foreach ($Candidate in $CandidatePaths) {

    $ChromeUserData = $Candidate.Path
    $UserName       = $Candidate.User

    Write-Log "---------------------------------------------------------"
    Write-Log "User: $UserName | Path: $ChromeUserData"

    try {

        if (!(Test-Path $ChromeUserData)) {
            Write-Log "Path not found, skipping."
            continue
        }

        $PossibleProfiles = Get-ChildItem $ChromeUserData -Directory -ErrorAction Stop

        if ($PossibleProfiles.Count -eq 0) {
            Write-Log "No subdirectories found."
            continue
        }

        Write-Log "Subdirectories found: $($PossibleProfiles.Count)"

        foreach ($ChromeProfile in $PossibleProfiles) {

            try {

                $ProfilePath = $ChromeProfile.FullName

                # Skip Chrome internal System Profile
                if ($ChromeProfile.Name -ieq "System Profile") {
                    Write-Log "Skipping System Profile."
                    continue
                }

                # --------------------------------------------------
                # Profile indicators
                # --------------------------------------------------

                $Indicators = @{
                    Preferences            = Test-Path (Join-Path $ProfilePath "Preferences")
                    SecurePreferences      = Test-Path (Join-Path $ProfilePath "Secure Preferences")
                    Bookmarks              = Test-Path (Join-Path $ProfilePath "Bookmarks")
                    History                = Test-Path (Join-Path $ProfilePath "History")
                    LoginData              = Test-Path (Join-Path $ProfilePath "Login Data")
                    Cookies                = Test-Path (Join-Path $ProfilePath "Cookies")
                    Extensions             = Test-Path (Join-Path $ProfilePath "Extensions")
                    LocalExtensionSettings = Test-Path (Join-Path $ProfilePath "Local Extension Settings")
                }

                # Hard gate: Preferences or Secure Preferences must exist
                $HardGate = $Indicators.Preferences -or $Indicators.SecurePreferences

                if (-not $HardGate) {
                    # Write-Log "Skipping $($ChromeProfile.Name): hard gate failed."
                    continue
                }

                # Weighted scoring
                $ProfileScore = 0
                if ($Indicators.Preferences)            { $ProfileScore += 4 }
                if ($Indicators.SecurePreferences)      { $ProfileScore += 4 }
                if ($Indicators.Extensions)             { $ProfileScore += 3 }
                if ($Indicators.LocalExtensionSettings) { $ProfileScore += 3 }
                if ($Indicators.History)                { $ProfileScore += 2 }
                if ($Indicators.LoginData)              { $ProfileScore += 2 }
                if ($Indicators.Bookmarks)              { $ProfileScore += 1 }
                if ($Indicators.Cookies)                { $ProfileScore += 1 }

                # Name pattern covers edge case: only Secure Preferences remains
                $IsNamedLikeProfile = ($ChromeProfile.Name -eq "Default") -or
                                      ($ChromeProfile.Name -match "^Profile \d+$")

                $IsLikelyProfile = ($ProfileScore -ge 6) -or
                                   ($HardGate -and $IsNamedLikeProfile)

                if (-not $IsLikelyProfile) {
                    # Write-Log "Skipping $($ChromeProfile.Name): score too low ($ProfileScore)."
                    continue
                }

                $TotalProfiles++
                
                # ADD THIS — increment per-browser profile counter here
                
                switch (Get-BrowserType $ChromeUserData) {
                    "Chrome"     { $CountChromeProfiles++     }
                    "ChromeSxS"  { $CountChromeSxSProfiles++  }
                    "ChromeBeta" { $CountChromeBetaProfiles++  }
                    "Chromium"   { $CountChromiumProfiles++   }
                    "Edge"       { $CountEdgeProfiles++       }
                }
                # Write-Log "Profile detected: $($ChromeProfile.Name) (Score: $ProfileScore)"
                Write-Log "Profile detected: $($ChromeProfile.Name)"

                # --------------------------------------------------
                # Delete Secure Preferences if present
                # --------------------------------------------------

                if ($Indicators.SecurePreferences) {

                    $TotalSecurePrefs++
                    $SecurePrefsPath = Join-Path $ProfilePath "Secure Preferences"

                    try {
                        $File = Get-Item $SecurePrefsPath -ErrorAction Stop
                        Write-Log "Secure Preferences found: $($File.Length) bytes, modified $($File.LastWriteTime)"

                        Remove-Item -Path $SecurePrefsPath -Force -ErrorAction Stop
                        $TotalDeleted++
                        Write-Log "Secure Preferences DELETED: $SecurePrefsPath"
                    }
                    catch {
                        $TotalErrors++
                        Write-Log "ERROR deleting Secure Preferences: $($_.Exception.Message)"
                    }

                } else {
                    Write-Log "Secure Preferences not found in $($ChromeProfile.Name)."
                }

            }
            catch {
                $TotalErrors++
                Write-Log "ERROR processing profile $($ChromeProfile.Name): $($_.Exception.Message)"
            }
        }

    }
    catch {
        $TotalErrors++
        Write-Log "ERROR accessing path ${ChromeUserData}: $($_.Exception.Message)"
    }
}

# -------------------------------------------------------
# Final Summary
# -------------------------------------------------------

Write-Log "========================================================="
Write-Log "SUMMARY"
Write-Log "========================================================="
Write-Log "Hostname                  : $env:COMPUTERNAME"
Write-Log "Total Profiles Detected   : $TotalProfiles"
Write-Log "--- Chrome               Installations : $CountChrome"
Write-Log "--- Chrome               Profiles      : $CountChromeProfiles"
Write-Log "--- Chrome SxS (Canary)  Installations : $CountChromeSxS"
Write-Log "--- Chrome SxS (Canary)  Profiles      : $CountChromeSxSProfiles"
Write-Log "--- Chrome Beta          Installations : $CountChromeBeta"
Write-Log "--- Chrome Beta          Profiles      : $CountChromeBetaProfiles"
Write-Log "--- Chromium             Installations : $CountChromium"
Write-Log "--- Chromium             Profiles      : $CountChromiumProfiles"
Write-Log "--- Microsoft Edge       Installations : $CountEdge"
Write-Log "--- Microsoft Edge       Profiles      : $CountEdgeProfiles"
Write-Log "SecurePrefs Found         : $TotalSecurePrefs"
Write-Log "SecurePrefs Deleted       : $TotalDeleted"
Write-Log "Total Errors              : $TotalErrors"
Write-Log "========================================================="