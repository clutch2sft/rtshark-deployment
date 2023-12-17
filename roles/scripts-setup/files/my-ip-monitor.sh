#!/bin/bash

. ./logging.inc

while true; do
    current_ip=$(nmcli -t -f IP4.ADDRESS dev show br0 | awk -F: '{print $2}' | cut -d'/' -f1)
    if [ -z "$current_ip" ]; then
        log_message "my-ip-monitor" "WARN" "No IP address found on br0. Skipping arping check."
    else
        # Check for timeout response
        if ! arping -0 -c 2 -w 3 -I br0 $current_ip | grep -q "Timeout"; then
            log_message "my-ip-monitor" "ERROR" "IP conflict detected for $current_ip. Reverting to fallback IP."
            nmcli con down br0
            nmcli con mod br0 ipv4.method auto
            nmcli con up br0
            systemctl restart find_wlan_ip_and_set.service
        else
            log_message "my-ip-monitor" "DEBUG" "No IP conflict detected for $current_ip."
        fi
    fi
    sleep 60
done
