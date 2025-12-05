#!/bin/bash

# -- WARNING --
# This script is a copy of what is on the server. It may not be up to date.
# Please refer to the server directly for the most current version.

# --- CONFIGURATION ---
SERVICE_NAME="satisfactory"
STEAMCMD_PATH="/opt/steamcmd/steamcmd.sh"
INSTALL_DIR="/opt/satisfactory"
APP_ID="1690800"
USER="satisfactory"
LOG_FILE="/var/log/satisfactory_updates.log"

# Ensure script is run with sudo
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (use sudo)"
  exit 1
fi

# Log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "========================================="
log "Starting Satisfactory Server Update"
log "========================================="

# Stop the server
log "Stopping Satisfactory Server..."
if systemctl stop $SERVICE_NAME; then
    log "✓ Server stopped successfully"
else
    log "✗ Failed to stop server"
    exit 1
fi

# Wait for graceful shutdown
sleep 5

# Update via SteamCMD
log "Starting SteamCMD Update..."
if sudo -u $USER $STEAMCMD_PATH +force_install_dir $INSTALL_DIR +login anonymous +app_update $APP_ID validate +quit; then
    log "✓ Update completed successfully"
else
    log "✗ Update failed"
    log "Attempting to restart server anyway..."
fi

# Restart the server
log "Restarting Satisfactory Server..."
if systemctl start $SERVICE_NAME; then
    log "✓ Server started successfully"
else
    log "✗ Failed to start server"
    exit 1
fi

# Wait for service to initialize
sleep 3

# Check final status
log "Final Status:"
systemctl status $SERVICE_NAME --no-pager | tee -a "$LOG_FILE"

log "========================================="
log "Update Complete"
log "========================================="
