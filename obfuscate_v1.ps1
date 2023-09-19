# This script encodes a script block using GZipstream,
# and then encodes again in Base64.
# Might be useful for obfuscation, but I think might 
# draw attention from EDRs or AVs instead.

# Specify the string to be compressed
$stringToCompress = @'
echo "Hello World" > C:\Users\User\Downloads\Output.txt
'@

# Convert the string to bytes using UTF-8 encoding
$stringBytes = [System.Text.Encoding]::UTF8.GetBytes($stringToCompress)

# Create a memory stream to hold the compressed data
$compressedStream = New-Object System.IO.MemoryStream

# Create a Gzip stream and write the compressed data to it
$gzipStream = [System.IO.Compression.GzipStream]::new($compressedStream, [System.IO.Compression.CompressionMode]::Compress)

# Write the compressed data to the Gzip stream
$gzipStream.Write($stringBytes, 0, $stringBytes.Length)

# Close the Gzip stream (important for finalizing the compression)
$gzipStream.Close()

# Convert the compressed stream to a base64-encoded string
$compressedBase64 = [Convert]::ToBase64String($compressedStream.ToArray())

# Optionally, you can save the compressed base64 string to a file or use it as needed
Write-Host "Compressed and Base64-encoded string:"
Write-Host $compressedBase64

# Decompression Function
Write-Host ([scriptblock]::create((New-Object System.IO.StreamReader(New-Object System.IO.Compression.GzipStream((New-Object System.IO.MemoryStream(,[System.Convert]::FromBase64String($compressedBase64))),[System.IO.Compression.CompressionMode]::Decompress))).ReadToEnd()))

pause
