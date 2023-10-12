$directoryPath = "C:\Temp\"

if (-not (Test-Path -Path $directoryPath -PathType Container)) {
    New-Item -Path $directoryPath -ItemType Directory
    echo "Directory created: $directoryPath"
} else {
    echo "Directory already exists: $directoryPath"
}

cd C:\Temp\

# Lists volume and outputs to a text file
'LIST VOLUME' | diskpart | Out-File -FilePath volume_list.txt

Get-Content volume_list.txt