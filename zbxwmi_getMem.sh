#!/bin/bash
# Usage: zbxwmi_getMem.sh "HOST_IP" "/path/to/windows_credentials"

DEBUG=false

HOST_IP="$1"
CREDS_PATH="$2"

# Extract CommittedBytes
committed_bytes=$(/usr/lib/zabbix/externalscripts/zbxwmi -a get -cred $CREDS_PATH -fields "CommittedBytes" -type "n" "Win32_PerfRawData_PerfOS_Memory" $HOST_IP)

# Extract CommitLimit
total_memory=$(/usr/lib/zabbix/externalscripts/zbxwmi -a get -cred $CREDS_PATH -fields "CommitLimit" -type "n" "Win32_PerfRawData_PerfOS_Memory" $HOST_IP)

#committed_bytes=$(echo "$json_output" | grep -o '"CommittedBytes": *[0-9]*' | grep -o '[0-9]*')

#total_memory=$(echo "$json_output" | grep -o '"CommitLimit": *[0-9]*' | grep -o '[0-9]*')

memory_percent=$(awk "BEGIN {printf \"%.2f\", ($committed_bytes / $total_memory) * 100}")

# Print or use the variables
if [ "$DEBUG" = true ]; then
        #echo $json_output
        echo "Committed Bytes: $committed_bytes"
        echo "Total Memory: $total_memory"
        echo "Committed Memory (Percentage): $memory_percent"
fi

echo $memory_percent
