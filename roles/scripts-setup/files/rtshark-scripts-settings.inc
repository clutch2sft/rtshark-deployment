# Define the network prefix and start and stop search addresses
NETWORK_PREFIX="120.13.212"
START_IP=254
END_IP=247

#define the interface for both setting the IP and capturing traffic
INTERFACE="br0"

# Define capture file settings
FILE_SIZE_LIMIT=76800  # In kilobytes, for 75MB
MAX_FILES=200            # Maximum number of files to keep
