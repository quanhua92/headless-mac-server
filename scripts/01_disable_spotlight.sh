#!/bin/bash

# Script: 01_disable_spotlight.sh
# -----------------------------------------------------------------------------
# Inputs: None
# Outputs: Disables Spotlight indexing.
# What it does: Unloads the Spotlight metadata server daemon.
# Why it's done: To reduce background CPU and I/O activity, saving resources on a headless server.
# How it works: Uses `sudo launchctl unload -w` to disable the service persistently.
# Expected result: Spotlight indexing is turned off. System resources used by mds and mdworker processes are freed.
# -----------------------------------------------------------------------------
# Important: This command requires sudo privileges.
# -----------------------------------------------------------------------------

# --- Configuration (inherit from 00_initial_setup.sh if run in same session or set here) ---
export HEADLESS_SERVER_USER=${HEADLESS_SERVER_USER:-$(whoami)}
export HEADLESS_BASE_DIR=${HEADLESS_BASE_DIR:-"/Users/$HEADLESS_SERVER_USER/headless-mac-server"}
LOG_DIR="$HEADLESS_BASE_DIR/logs"
MAIN_LOG_FILE="$LOG_DIR/setup.log"
SCRIPT_NAME=$(basename "$0")

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$SCRIPT_NAME] $1" | tee -a "$MAIN_LOG_FILE"
}

# --- Main Logic ---
log_action "Starting Spotlight disabling..."

if ! sudo launchctl list | grep -q com.apple.metadata.mds; then
    log_action "Spotlight (com.apple.metadata.mds) already seems to be unloaded or not found."
else
    log_action "Disabling Spotlight indexing (com.apple.metadata.mds)..."
    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist
    if [ $? -eq 0 ]; then
        log_action "Spotlight indexing disabled successfully."
    else
        log_action "ERROR: Failed to disable Spotlight indexing. Please check permissions or if the service path is correct."
        exit 1
    fi
fi

# Also disable for loginwindow if it exists (older systems)
if [ -f /System/Library/LaunchAgents/com.apple.Spotlight.plist ]; then
    log_action "Attempting to disable Spotlight LaunchAgent (com.apple.Spotlight)..."
    # This would need to be done per user, or by targeting the user's launchd domain.
    # For a system-wide effect on a headless server, the mds daemon is the primary target.
    # sudo -u "$HEADLESS_SERVER_USER" launchctl unload -w /System/Library/LaunchAgents/com.apple.Spotlight.plist
    # However, modifying system LaunchAgents is generally not recommended without specific need.
    # The main daemon com.apple.metadata.mds is the key one for resource saving.
    log_action "Skipping user-specific Spotlight agent disabling, focusing on system daemon."
fi


log_action "Spotlight disabling script finished."