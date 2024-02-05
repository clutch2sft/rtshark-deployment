#!/bin/bash

fix_dhcp_failed() {
    local con_name="$INTERFACE"

    log_message $SCRIPT_NAME "DEBUG" "fix_dhcp_failed: Attempting to manage and configure $con_name with a static Zeroconf address."

    # Set static IP (Zeroconf address)
    if ! nmcli con mod "$con_name" ipv4.method manual ipv4.addresses "$ZC_IP"/16 ipv4.gateway "$ZC_GW"; then
        log_message $SCRIPT_NAME "DEBUG" "fix_dhcp_failed: Failed to set IP for $con_name"
        return 1
    fi

    # Set the connection to autoconnect
    if ! nmcli con mod "$con_name" connection.autoconnect yes; then
        log_message $SCRIPT_NAME "DEBUG" "fix_dhcp_failed: Failed to set autoconnect for $con_name"
        return 1
    fi

    # Bring the connection up
    if ! nmcli con up "$con_name"; then
        log_message $SCRIPT_NAME "DEBUG" "fix_dhcp_failed: Failed to bring up $con_name"
        return 1
    fi

    # Give it some time to apply the settings and come up
    sleep 5
    LINK_MAX_WAIT_TIME=60  # Maximum time to wait for the interface to be up and have an IP (in seconds)
    LINK_CHECK_INTERVAL=5  # Time interval between checks (in seconds)
    # Start the timer
    end_time=$((SECONDS + LINK_MAX_WAIT_TIME))

    # Check if the interface is up and has an IP address
    while [[ $SECONDS -lt $end_time ]]; do
        if ip link show "$INTERFACE" | grep -qw 'state UP'; then
            log_message $SCRIPT_NAME "DEBUG" "$INTERFACE is up."
            if ip addr show "$INTERFACE" | grep -q 'inet '; then
                ip_address=$(ip addr show "$INTERFACE" | grep 'inet ' | awk '{print $2}')
                log_message $SCRIPT_NAME "DEBUG" "$INTERFACE has IP address $ip_address."

                if [[ $ip_address == 169.254.* ]]; then
                    log_message $SCRIPT_NAME "DEBUG" "$INTERFACE has a Zeroconf address. It might not have full network connectivity."
                    #exit 0  # Exit with success
                    break
                else
                    log_message $SCRIPT_NAME "DEBUG" "$INTERFACE has a regular IP address."
                    #exit 0  # Exit with success
                    break
                fi
            else
                log_message $SCRIPT_NAME "DEBUG" "$INTERFACE does not have an IP address. Checking again in $LINK_CHECK_INTERVAL seconds."
            fi
        else
            log_message $SCRIPT_NAME "DEBUG" "$INTERFACE is not up. Checking again in $LINK_CHECK_INTERVAL seconds."
        fi
        # Wait for the specified interval before checking again
        sleep $LINK_CHECK_INTERVAL
    done

    log_message $SCRIPT_NAME "DEBUG" "fix_dhcp_failed: Address is set $ZC_IP/16, ipv4.gateway $ZC_GW"
    return 0  # Explicitly exit with code 0 indicating success
}
