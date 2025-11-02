#!/bin/bash

SCRIPT_NAME="configure.sh"
SERVICE_NAME="monitoring"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/monitoring/"
SYSTEMD_DIR="/etc/systemd/system"

show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [command]

Commands:
    install   - Install and start the monitoring service
    uninstall - Stop and remove the monitoring service  
    help      - Show this help message

Description:
    This script installs or uninstalls a systemd monitoring service
    that periodically checks a remote endpoint.

Installation steps:
    1. Copies monitoring script to $INSTALL_DIR/
    2. Copies systemd service and timer files to $SYSTEMD_DIR/
    3. Enables and starts the timer

Uninstallation steps:
    1. Stops and disables the service
    2. Removes all installed files
EOF
}

install_service() {
    echo "Installing monitoring service..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo "Error: Installation requires root privileges. Run with sudo."
        exit 1
    fi
    
    # Check if source files exist
    if [[ ! -f "src/monitoring.sh" ]]; then
        echo "Error: src/monitoring.sh not found!"
        exit 1
    fi
    
    if [[ ! -f "systemd/monitoring.service" ]]; then
        echo "Error: systemd/monitoring.service not found!"
        exit 1
    fi
    
    if [[ ! -f "systemd/monitoring.timer" ]]; then
        echo "Error: systemd/monitoring.timer not found!"
        exit 1
    fi
    
    # Copy script to install directory
    echo "Copying monitoring script to $INSTALL_DIR/"
    mkdir -p $INSTALL_DIR
    cp src/monitoring.sh $INSTALL_DIR/monitoring.sh
    chmod +x $INSTALL_DIR/monitoring.sh

    # Copy hooks-script to install directory
    echo "Copying monitoring hooks script to $INSTALL_DIR/"
    mkdir -p $INSTALL_DIR
    cp src/monitoring-hooks.sh $INSTALL_DIR/monitoring-hooks.sh
    chmod +x $INSTALL_DIR/monitoring-hooks.sh

    # Copy configuration
    echo "Copying monitoring config to $CONFIG_DIR/"
    mkdir -p $CONFIG_DIR
    cp src/monitoring.conf $CONFIG_DIR/monitoring.conf
    
    # Copy systemd files
    echo "Copying systemd files to $SYSTEMD_DIR/"
    mkdir -p $SYSTEMD_DIR
    cp systemd/monitoring.service $SYSTEMD_DIR/
    cp systemd/monitoring.timer $SYSTEMD_DIR/
    
    # Reload systemd and enable service
    echo "Reloading systemd daemon..."
    systemctl daemon-reload
    
    echo "Enabling and starting timer..."
    systemctl enable monitoring.timer
    systemctl start monitoring.timer
    
    echo "Installation completed successfully!"
    echo "Service status: systemctl status monitoring.timer"
    echo "View logs: journalctl -u monitoring.service"
}

uninstall_service() {
    echo "Uninstalling monitoring service..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo "Error: Uninstallation requires root privileges. Run with sudo."
        exit 1
    fi
    
    # Stop and disable service
    echo "Stopping and disabling timer..."
    systemctl stop monitoring.timer 2>/dev/null || true
    systemctl disable monitoring.timer 2>/dev/null || true
    
    # Remove files
    echo "Removing installed files..."
    rm -f $INSTALL_DIR/monitoring.sh
    rm -f $INSTALL_DIR/monitoring-hooks.sh
    rm -f $SYSTEMD_DIR/monitoring.service
    rm -f $SYSTEMD_DIR/monitoring.timer
    rm -f /var/log/monitoring.log
    
    # Reload systemd
    echo "Reloading systemd daemon..."
    systemctl daemon-reload
    
    echo "Uninstallation completed successfully!"
}

case "$1" in
    install)
        install_service
        ;;
    uninstall)
        uninstall_service
        ;;
    help|*)
        show_help
        ;;
esac