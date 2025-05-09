#!/bin/bash

# Script: 02_disable_time_machine.sh
# -----------------------------------------------------------------------------
# Inputs: None
# Outputs: Disables Time Machine backups.
# What it does: Uses `tmutil` to disable Time Machine.
# Why it's done: To prevent automatic backups that consume resources and disk space, unsuitable for a dedicated server.
# How it works: Executes `sudo tmutil disable`.
# Expected result: Time Machine is disabled. No automatic backups will occur.
# -----------------------------------------------------------------------------
# Important: This command requires sudo privileges.
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
log_action "Starting Time Machine disabling..."

if sudo tmutil destinationinfo | grep -q "Kind : Local"; then
    log_action "Time Machine appears to be configured. Disabling..."
    sudo tmutil disable
    if [ $? -eq 0 ]; then
        log_action "Time Machine disabled successfully."
    else
        log_action "ERROR: Failed to disable Time Machine."
        exit 1
    fi
else
    log_action "Time Machine does not appear to be configured or is already disabled."
fi

log_action "Time Machine disabling script finished."