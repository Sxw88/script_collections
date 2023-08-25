# This script sends an email through Outlook
# It creates a C# COM object to send the email, and then deletes the email

$version = 8

# mailserver FQDN - to test connection to SMTP server before sending
$mailserver = "mail.server.com"
# SMTP Port Number - to test connection to SMTP server before sending
$mailport = 888

# Recipient
$TO = "receipient.name@webmail.com"
# Subject and Content of Email
$SUBJECT = "Automated Email | Please Ignore" 
$BODY = "Test Mail sent from Powershell"

# Attachments (if any)
$ATTACHMENTS = "C:\Users\User\Downloads\test.txt"

function Get-TimeStamp {
	Get-Date -Format "dd/MM/yyyy H:mm:ss"
}

function Write-Log {
	param (
		$LogLvl = "DEBUG",
		$LogMsg = " - "
	)
	& Write-Output "$(Get-TimeStamp) [$LogLvl] $LogMsg" | Tee-Object -Append -FilePath $PSScriptRoot\Output.log | Write-Host
}

function Invoke-SetProperty {
    # Auxiliar function to set properties. The SendUsingAccount property wouldn't be set in a different way
    param(
        [__ComObject] $Object,
        [String] $Property,
        $Value 
    )
    [Void] $Object.GetType().InvokeMember($Property,"SetProperty",$NULL,$Object,$Value)
}

# Check if SMTP server is reachable
Write-Log -LogLvl INFO -LogMsg "=== Running Outlook Automail Script version <$version> ==="
Write-Log -LogLvl INFO -LogMsg "Checking connection to Mail Server ..."
$testSmtp = Test-NetConnection -ComputerName $mailserver -Port $mailport
$testSmtp = echo $testSmtp | FindStr "TcpTestSucceeded"
$testSmtp = $testSmtp + "test"

# loop if the mail server is not available, try again in 5 minutes
while ($testSmtp -notlike "*True*") {
	Start-Sleep -Seconds 300 # Sleep for 5 minutes and try again
	$testSmtp = Test-NetConnection -ComputerName $mailserver -Port $mailport
	$testSmtp = echo $testSmtp | FindStr "TcpTestSucceeded"
	$testSmtp = $testSmtp + "test"
	Write-Log -LogLvl WARN -LogMsg "Mail Server at <$mailserver> is not reachable - sleep for 5 minutes"
} 

Write-Log -LogLvl INFO -LogMsg "Mail Server is reachable - proceed to send mail"

Write-Log -LogLvl DEBUG -LogMsg "Creating Outlook Mail Object"
try {
	$outlook = New-Object -ComObject Outlook.Application
	
	$email = $outlook.CreateItem(0)
		
	Write-Log -LogLvl INFO -LogMsg "Getting the user's Sent Items folder"
	$sentItems = $outlook.Session.GetDefaultFolder(5)
		
	Write-Log -LogLvl INFO -LogMsg "Getting the user's Deleted Items folder"
	$deletedItems = $outlook.Session.GetDefaultFolder(3)
	
	#Invoke-SetProperty -Object $email -Property "SendUsingAccount" -Value $targetAccount
	$email.To = $TO
	$email.Subject = $SUBJECT
	$email.Body = $BODY
	
	### TODO: Check if $ATTACHMENTS exists before sending
	#$email.Attachments.Add($ATTACHMENTS)
	
	# Before sending the email check Sent Items folder for matching emails
	$sentCount = 0
	foreach ($emailItem in $sentItems.Items) {
		# Check if the email subject contains the match string and it is a sent email
		if ($emailItem.Subject -like "*$Subject*" -and $emailItem.Sent) {
			$sentCount = $sentCount + 1
		}
	}
	Write-Log -LogLvl DEBUG -LogMsg "$sentCount matching emails found in Sent Items folder"
	
	# Sending email
	Write-Log -LogLvl INFO -LogMsg "Sending e-mail to target destination: $To"
	$email.Send()
	
	# After sending email, check again to make sure email is in Sent Items folder
	$sentCount2 = 0
	foreach ($emailItem in $sentItems.Items) {
		# Check if the email subject contains the match string and it is a sent email
		if ($emailItem.Subject -like "*$Subject*" -and $emailItem.Sent) {
			$sentCount2 = $sentCount2 + 1
		}
	}
	
	while ($sentCount -ge $sentCount2) {
		# Count matching emails in the Sent Items folder again
		$sentCount2 = 0
		foreach ($emailItem in $sentItems.Items) {
			# Check if the email subject contains the match string and it is a sent email
			if ($emailItem.Subject -like "*$Subject*" -and $emailItem.Sent) {
				$sentCount2 = $sentCount2 + 1
			}
		}
		Write-Log -LogLvl DEBUG -LogMsg "$sentCount2 matching emails found in Sent Items folder"
		# Sleep for 5 seconds and try again if email has not been sent
		Start-Sleep -Seconds 5
	}
	
	# Loop through each email in the Sent Items folder
	foreach ($emailItem in $sentItems.Items) {
		
		# Check if the email subject contains the match string and it is a sent email
		if ($emailItem.Subject -like "*$Subject*" -and $emailItem.Sent) {
			Write-Log -LogLvl WARN -LogMsg "Email found in Sent Items folder, Deleting 1 email ..."
			try {
				$emailItem.Delete() # Delete the email
			} catch {
				Write-Log -LogLvl ERROR -LogMsg "Failed to delete email in Sent Items folder"
				Write-Log -LogLvl ERROR -LogMsg "$_"
			}
		}
	}
	
	# Loop through each email in the Deleted Items folder
	foreach ($emailItem in $deletedItems.Items) {
		
		# Check if the email subject contains the match string and it is a sent email
		if ($emailItem.Subject -like "*$Subject*" -and $emailItem.Sent) {
			Write-Log -LogLvl WARN -LogMsg "Email found in Deleted Items folder, Deleting 1 email ..."
			try {
				$emailItem.Delete() # Delete the email
			} catch {
				Write-Log -LogLvl ERROR -LogMsg "Failed to delete email in Deleted Items folder"
				Write-Log -LogLvl ERROR -LogMsg "$_"
			}
		}
	}
			
	# Clean up the Outlook application object
	[System.Runtime.Interopservices.Marshal]::ReleaseComObject($outlook) | Out-Null
	Remove-Variable outlook
} catch {
	Write-Log -LogLvl ERROR -LogMsg "$_"
}

Write-Log -LogLvl INFO -LogMsg "Exiting ..."
Start-Sleep -Seconds 3
