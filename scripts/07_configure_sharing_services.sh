#!/bin/bash

# Script: 07_configure_sharing_services.sh
# -----------------------------------------------------------------------------
# Inputs: None
# Outputs: Disables File Sharing (AFP, SMB) and Screen Sharing.
# What it does: Unloads the respective launch daemons.
# Why it's done: To reduce attack surface and resource consumption. SSH is the preferred access method.
#                Screen Sharing is explicitly disabled as per user request.
# How it works: Uses `sudo launchctl unload -w` for each service.
# Expected result: AFP, SMB, and Screen Sharing services are disabled.
# -----------------------------------------------------------------------------
# Important: These commands require sudo privileges.
# Ensure SSH (Remote Login) is enabled and working before disabling Screen Sharing if it's your only other remote access.
# -----------------------------------------------------------------------------

# --- Configuration ---
export HEADLESS_SERVER_USER=${HEADLESS_SERVER_USER:-$(whoami)}
export HEADLESS_BASE_DIR=${HEADLESS_BASE_DIR:-"/Users/$HEADLESS_SERVER_USER/headless-mac-server"}
LOG_DIR="$HEADLESS_BASE_DIR/logs"
MAIN_LOG_FILE="$LOG_DIR/setup.log"
SCRIPT_NAME=$(basename "$0")

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$SCRIPT_NAME] $1" | tee -a "$MAIN_LOG_FILE"
}

# --- Main Logic ---
log_action "Starting configuration of sharing services..."

# Disable Apple File Sharing (AFP)
log_action "Disabling Apple File Sharing (AFP)..."
if [ -f /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist ]; then
    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist 2>/dev/null || true
    log_action "Apple File Sharing (AFP) unload attempted."
else
    log_action "Apple File Sharing (AFP) plist not found, assuming not active or already removed."
fi

# Disable SMB File Sharing
log_action "Disabling SMB File Sharing..."
if [ -f /System/Library/LaunchDaemons/com.apple.smbd.plist ]; then
    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true
    log_action "SMB File Sharing unload attempted."
else
    log_action "SMB File Sharing plist not found, assuming not active or already removed."
fi

# Disable Screen Sharing
log_action "Disabling Screen Sharing..."
log_action "IMPORTANT: Ensure you have SSH access (Remote Login in System Settings > Sharing) before proceeding."
# Ask for confirmation
read -p "Are you sure you want to disable Screen Sharing? (yes/NO): " confirmation
if [[ "$confirmation" == "yes" ]]; then
    if [ -f /System/Library/LaunchDaemons/com.apple.screensharing.plist ]; then
        sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true
        # Also disable via defaults command for extra measure, though launchctl should suffice
        sudo defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool true 2>/dev/null || true
        log_action "Screen Sharing unload attempted and override set."
    else
        log_action "Screen Sharing plist not found, assuming not active or already removed."
    fi
    log_action "Screen Sharing disabled."
else
    log_action "Screen Sharing was NOT disabled by user choice."
fi

# You might want to disable other services like Printer Sharing if not needed.
# sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.cupsd.plist (Be careful, some apps might want this)

log_action "Sharing services configuration script finished."