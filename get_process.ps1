# Lists out current running processes on a Windows computer
# Works best if deployed through a remote shell

$directoryPath = "C:\Temp\"

if (-not (Test-Path -Path $directoryPath -PathType Container)) {
    New-Item -Path $directoryPath -ItemType Directory
    echo "Directory created: $directoryPath"
} else {
    echo "Directory already exists: $directoryPath"
}

cd C:\Temp\

$timestamp = Get-Date -Format "yyyy-MM-dd_HH.mm.ss"

# Lists volume and outputs to a text file
Get-Process | Out-File -FilePath "processes_$timestamp.txt"

Get-Content "processes_$timestamp.txt"