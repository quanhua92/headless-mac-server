#!/bin/bash

# Script: 04_disable_screen_saver.sh
# -----------------------------------------------------------------------------
# Inputs:
#   - HEADLESS_SERVER_USER: The user for whom to disable the screen saver. (Default: current user)
# Outputs: Disables the screen saver for the specified user.
# What it does: Sets the screen saver idle time to 0.
# Why it's done: Unnecessary for a headless server and saves minimal resources.
# How it works: Uses `defaults write` command. This should be run as the user or target the user's domain.
# Expected result: The screen saver will not activate for the configured user.
# -----------------------------------------------------------------------------
# Important: This script modifies user-level preferences.
# It should be run as the $HEADLESS_SERVER_USER, or use `sudo -u $HEADLESS_SERVER_USER`.
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
log_action "Starting screen saver disabling for user $HEADLESS_SERVER_USER..."

# Check if running as the target user, otherwise use sudo -u
if [ "$(whoami)" == "$HEADLESS_SERVER_USER" ]; then
    log_action "Running 'defaults write' as current user ($HEADLESS_SERVER_USER)."
    defaults write com.apple.screensaver idleTime -int 0
else
    log_action "Current user is $(whoami), targeting $HEADLESS_SERVER_USER. Using 'sudo -u $HEADLESS_SERVER_USER'."
    # Ensure the user's home directory exists and preferences can be written
    if [ ! -d "/Users/$HEADLESS_SERVER_USER" ]; then
        log_action "ERROR: Home directory for $HEADLESS_SERVER_USER not found. Cannot set screen saver."
        exit 1
    fi
    sudo -u "$HEADLESS_SERVER_USER" defaults write com.apple.screensaver idleTime -int 0
fi

if [ $? -eq 0 ]; then
    log_action "Screen saver idleTime set to 0 for user $HEADLESS_SERVER_USER successfully."
else
    log_action "ERROR: Failed to set screen saver idleTime for user $HEADLESS_SERVER_USER."
    # No exit 1, as this is less critical than system services
fi

# Additionally, for systems that might use `legacyScreenSaver`
# sudo -u "$HEADLESS_SERVER_USER" defaults write com.apple.screensaver.legacyScreenSaver idleTime -int 0

log_action "Screen saver disabling script finished."