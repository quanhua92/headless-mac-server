#!/bin/bash

# Script: 03_configure_power_management.sh
# -----------------------------------------------------------------------------
# Inputs: None
# Outputs: Configures power settings for always-on server operation.
# What it does: Disables sleep, hibernation mode, and system sleep timer.
# Why it's done: To ensure the Mac mini server remains active and accessible.
# How it works: Uses `sudo pmset` to adjust various power settings.
# Expected result: The system will not go to sleep or hibernate automatically.
# -----------------------------------------------------------------------------
# Important: These commands require sudo privileges.
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
log_action "Starting power management configuration..."

log_action "Setting sleep to 0 (never sleep)..."
sudo pmset -a sleep 0
log_action "Setting hibernatemode to 0 (disable hibernation)..."
sudo pmset -a hibernatemode 0
log_action "Setting disablesleep to 1 (ensure sleep is truly disabled)..."
sudo pmset -a disablesleep 1 # For newer macOS versions, this might be key

# Optional: Disable disk sleep if you have spinning drives and want them always active
# log_action "Setting disksleep to 0 (disable disk sleep)..."
# sudo pmset -a disksleep 0

# Optional: Disable wake on network access if not needed (usually desired for a server)
# log_action "Ensuring womp (wake on magic packet/network) is 1 (enabled)..."
# sudo pmset -a womp 1

# Verify settings
log_action "Current power settings (pmset -g):"
sudo pmset -g | tee -a "$MAIN_LOG_FILE"

log_action "Power management configuration finished."