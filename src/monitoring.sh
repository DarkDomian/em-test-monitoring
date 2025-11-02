#!/bin/bash

ENDPOINT_URL="https://test.com/monitoring/test/api"
SERVICE_NAME="monitoring-daemon"
LOG_FILE="/var/log/monitoring.log"

# Ensure log file exists and is writable
setup_logging() {
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
}

# Log function with timestamp and tag
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[$timestamp] [$SERVICE_NAME] [$1] $2"

    echo "$message" >> "$LOG_FILE"
    echo "$message"
}

# Function to make HTTPS request
check_endpoint() {
    local response
        
    # Make HTTPS request with timeout and metrics
    response=$(curl -s -o /dev/null -w "Endpoint responded with HTTP%{http_code} (%{time_total}s)" \
                    --max-time 10 \
                    --connect-timeout 5 \
                    "$ENDPOINT_URL" 2>/dev/null)
    
    local curl_exit_code=$?
    
    # Handle different curl exit codes
    case $curl_exit_code in
        0)
            if [[ "$response_code" =~ ^2[0-9][0-9]$ ]]; then
                log_message "SUCCESS" "$response"
                return 0
            else
                log_message "WARNING" "$response"
                return 1
            fi
            ;;
        7|6|28)
            log_message "ERROR" "Cannot connect to endpoint (curl exit: $curl_exit_code)"
            return 2
            ;;
        60)
            log_message "ERROR" "SSL certificate verification failed"
            return 3
            ;;
        *)
            log_message "ERROR" "Unexpected error (curl exit: $curl_exit_code)"
            return 4
            ;;
    esac
}

# Main execution
main() {
    setup_logging
    
    # Perform the check
    check_endpoint
    local check_result=$?

    exit $check_result
}

# Handle script termination
trap 'log_message "Script interrupted"; exit 130' INT TERM

# Run main function
main