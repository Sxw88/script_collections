# This script scans the user's Outlook inbox folder for any emails
# with the predefined titles within the predefined time frame.

# If any matches are found, it will download any attachments 
# and name it based on the prefix / suffix specified

# Input 
#	- Time frame (how many hours ago), 
#	- Match criteria @(Email Subject, Download Prefix, Download Suffix)

# Output 
#	- downloads email attachment

# Pre-defined criteria to match with email items in the inbox
$criteria = @(
	# Email Subject, 	Download Prefix, 	Download Suffix
	@("Test Email", 	"abc", 			"def"),
	@("Mention", 		"ghi", 			"jkl")
)

function Scan-Mail2 {
	param (
		[int]$HoursAgo = 24,
		[array]$Criteria
	)
	
	# Define the time frame (1 hour ago)
	$startTime = (Get-Date).AddHours(-$hoursAgo)

	# Create an Outlook application object
	$outlook = New-Object -ComObject Outlook.Application

	# Get the user's inbox folder
	$inbox = $outlook.session.GetDefaultFolder(6)  # 6 represents the inbox folder

	foreach ($emailItem in $inbox.Items) {
		# Check the email by received time
		if ($emailItem.ReceivedTime -ge $startTime) {
			foreach ($criteriaItem in $Criteria) { # loop through the pre-defined criteria array
				$subject = $criteriaItem[0]
				if ($emailItem.Subject -like "*$subject*") {
					Write-Host "================ A Matching Email has been found! ================"
					Write-Host "Sender   : $($emailItem.Sender.Name) <$($emailItem.SenderEmailAddress)>"
					Write-Host "Rec Time : $($emailItem.ReceivedTime)"
					Write-Host "Subject  : $($emailItem.Subject)"
					#Write-Host "Body     : `n"
					#Write-Host $emailItem.Body
					Write-Host "`n"
				}
			}
		}
	}

	# Release COM objects
	[System.Runtime.Interopservices.Marshal]::ReleaseComObject($inbox) | Out-Null
	[System.Runtime.Interopservices.Marshal]::ReleaseComObject($outlook) | Out-Null
}

Scan-Mail2 -Criteria $criteria

pause