#!/bin/bash
SERVICE_NAME="monitoring-daemon"
LOG_FILE="/var/log/monitoring.log"

log_hook() {
    local hook_type="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] [$SERVICE_NAME] [hook] [$hook_type] $message"
    
    echo "$log_entry" >> "$LOG_FILE"
    logger -t "$SERVICE_NAME-hook" "$hook_type: $message"
}

case "$1" in
    reload)
        log_hook "reload" "Service reload requested"
        ;;
    *)
        log_hook "unknown" "Unknown hook: $1"
        ;;
esac