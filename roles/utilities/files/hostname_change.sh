#!/bin/bash

# Check if a new hostname was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 new_hostname"
    exit 1
fi

new_hostname="$1"

# Change the hostname in /etc/hostname
echo $new_hostname | sudo tee /etc/hostname

# Update /etc/hosts
sudo sed -i "s/127.0.0.1   localhost .*/127.0.0.1   localhost $new_hostname/" /etc/hosts
sudo sed -i "s/::1         localhost .*/::1         localhost $new_hostname ip6-localhost ip6-loopback/" /etc/hosts

# Apply the new hostname immediately without rebooting
sudo hostname $new_hostname

echo "Hostname changed to $new_hostname"