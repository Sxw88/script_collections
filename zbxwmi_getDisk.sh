#!/bin/bash
# Usage: zbxwmi_getDisk.sh "HOST_IP" "/path/to/windows_credentials" "C:"

DEBUG=false

HOST_IP="$1"
CREDS_PATH="$2"
WMI_TARGETED_DRIVE="$3"         # Example - C: or D:

json_output=$(/usr/lib/zabbix/externalscripts/zbxwmi -a json -cred $CREDS_PATH -fields "Size,FreeSpace" -type "n,n" -item $WMI_TARGETED_DRIVE "Win32_LogicalDisk" $HOST_IP)

# Extract FreeSpace
free_space=$(echo "$json_output" | grep -o '"FreeSpace": *[0-9]*' | grep -o '[0-9]*')

# Extract Size
size=$(echo "$json_output" | grep -o '"Size": *[0-9]*' | grep -o '[0-9]*')

# Calculate Used Space
used_space=$((size - free_space))

used_percent=$(awk "BEGIN {printf \"%.2f\", ($used_space / $size) * 100}")

# Print or use the variables
if [ "$DEBUG" = true ]; then
        echo $json_output
        echo "FreeSpace: $free_space"
        echo "Size: $size"
        echo "UsedSpace: $used_space"
        echo "UsedSpace (Percentage): $used_percent"
fi

echo $used_percent
