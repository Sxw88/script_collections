#!/bin/bash

# Bash script to restart a service. 
# Run a cronjob to schedule the script 
# and it should restart the service (line 14) 
# and keep logs at specified location (line 9)

service="servicename.service"
log_file="/path/to/restart_svc.log"

# limits the log file size
max_lines=10

systemctl restart $service

time=$(timedatectl | grep "Local time")
time=${time:16}

# Check if the log file exists
if [ -f "$log_file" ]; then

        # Get the current line count
        line_count=$(wc -l < "$log_file")

        # if line count exceeds limit, remove oldest lines
        if [ "$line_count" -ge "$max_lines" ]; then
                lines_to_remove=$((line_count - max_lines))
                sed -i "1,${lines_to_remove}d" "$log_file"
        fi
fi

# Log local time
echo -n "Script executed at l$time. Status: " >> $log_file

# Check service status
svc_status=$(systemctl status $service)
value_status=$(echo $svc_status | grep "active (running)" | wc -l)

if [ $value_status -ge 1 ]; then
        echo -e "\e[1;32m$service is up and running\e[0m" >> $log_file
else
        echo -e "\e[1;41m$service failed to start\e[0m" >> $log_file
fi
