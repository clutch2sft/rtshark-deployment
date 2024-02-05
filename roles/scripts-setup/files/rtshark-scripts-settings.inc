# Define the network prefix and start and stop search addresses
NETWORK_PREFIX="120.13.212" #CAUTION this can be overridden by the systemd service calling the script
START_IP=254
END_IP=247

#define the interface for both setting the IP and capturing traffic
INTERFACE="br0" #CAUTION this can be overridden by the systemd service calling the script

# Define capture file settings
FILE_SIZE_LIMIT=76800  # In kilobytes, for 75MB
MAX_FILES=200            # Maximum number of files to keep

# Define Zeroconf IP and Gateway
ZC_IP="169.254.222.69"
ZC_GW="169.254.222.1"

# Constants for time intervals
MAX_WAIT_TIME_FOR_DHCP=120  # Maximum time to wait for DHCP to succeed
CHECK_INTERVAL=10           # Interval to check the status

# Define an array of slave interface names
declare -a slave_interfaces=("eth0" "lan0")


#define the program for debug output
SCRIPT_NAME="find_interface_ip_and_set"
