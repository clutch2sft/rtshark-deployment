# logging.sh

# Define log levels
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

# Set the minimum log level for messages to be recorded
MIN_LOG_LEVEL=$LOG_LEVEL_INFO

# Function to send logs to syslog
# Now accepts an additional argument for the script name
log_message() {
    script_name=$1
    level_name=$2
    message=$3

    # Assign numeric values to level names
    case $level_name in
        DEBUG)
            level=$LOG_LEVEL_DEBUG
            level_priority="user.debug"
            ;;
        INFO)
            level=$LOG_LEVEL_INFO
            level_priority="user.info"
            ;;
        WARN)
            level=$LOG_LEVEL_WARN
            level_priority="user.warn"
            ;;
        ERROR)
            level=$LOG_LEVEL_ERROR
            level_priority="user.err"
            ;;
        *)
            echo "Unknown log level: $level_name"
            exit 1
            ;;
    esac

    # Check if the message's level is greater than or equal to the minimum level
    if [ $level -ge $MIN_LOG_LEVEL ]; then
        logger -p $level_priority -t "$script_name" "$message"
    fi
}
