Import-Module ActiveDirectory

# Usage: Run this script on Domain Controller to find out which accounts have Service Principal Name (SPN) enabled.

# Helper function to decode the Encryption Bitmask
function Get-EncryptionName ($bitmask) {
    if ($null -eq $bitmask) { return "Default (Not Explicitly Set)" }
    $types = @()
    if ($bitmask -band 1)  { $types += "DES_CRC" }
    if ($bitmask -band 2)  { $types += "DES_MD5" }
    if ($bitmask -band 4)  { $types += "RC4" }
    if ($bitmask -band 8)  { $types += "AES128" }
    if ($bitmask -band 16) { $types += "AES256" }
    if ($types.Count -eq 0) { return "None/Unknown ($bitmask)" }
    return ($types -join ", ")
}

Write-Host "--- Scanning for USER accounts with SPNs & Encryption Status ---" -ForegroundColor Cyan
$UserSPNs = Get-ADUser -LDAPFilter "(servicePrincipalName=*)" -Properties servicePrincipalName, "msDS-SupportedEncryptionTypes" |
  Select-Object Name, SamAccountName,
    @{Name="Encryption_Types"; Expression={ Get-EncryptionName $_."msDS-SupportedEncryptionTypes" }},
    @{Name="SPN_Count"; Expression={@($_.servicePrincipalName).Count}},
    @{Name="ServicePrincipalName"; Expression={$_.servicePrincipalName}}

if (@($UserSPNs).Count -gt 0) {
  $UserSPNs | Out-GridView -Title "User Accounts Encryption Audit"
  Write-Host "[!] Found $(@($UserSPNs).Count) user account(s). Check the GridView for AES status." -ForegroundColor Yellow
} else {
  Write-Host "[+] No user accounts have SPNs set." -ForegroundColor Green
}

Write-Host "`n--- Scanning for MANAGED SERVICE accounts (gMSA/MSA) with SPNs ---" -ForegroundColor Cyan
$SvcSPNs = Get-ADServiceAccount -LDAPFilter "(servicePrincipalName=*)" -Properties servicePrincipalName |
  Select-Object Name, SamAccountName,
    @{Name="SPN_Count";Expression={@($_.servicePrincipalName).Count}},
    @{Name="ServicePrincipalName";Expression={$_.servicePrincipalName}}

if (@($SvcSPNs).Count -gt 0) {
  $SvcSPNs | Out-GridView -Title "Service Accounts (gMSA/MSA) with SPNs Found"
  Write-Host "[!] Found $(@($SvcSPNs).Count) managed service account(s) with SPNs set." -ForegroundColor Yellow
} else {
  Write-Host "[+] No managed service accounts have SPNs set." -ForegroundColor Green
}

Write-Host "`n--- Scanning for COMPUTER accounts with SPNs ---" -ForegroundColor Cyan
$ComputerSPNs = Get-ADComputer -LDAPFilter "(servicePrincipalName=*)" -Properties servicePrincipalName |
  Select-Object Name, DNSHostName,
    @{Name="SPN_Count";Expression={@($_.servicePrincipalName).Count}},
    @{Name="ServicePrincipalName";Expression={$_.servicePrincipalName}}

Write-Host "[i] Found $(@($ComputerSPNs).Count) computer account(s) with SPNs." -ForegroundColor Gray
# Optional:
# $ComputerSPNs | Out-GridView -Title "Computer Accounts with SPNs Found"