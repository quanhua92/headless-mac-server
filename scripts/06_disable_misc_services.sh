#!/bin/bash

# Script: 06_disable_misc_services.sh
# -----------------------------------------------------------------------------
# Inputs: None
# Outputs: Disables Power Nap and Sudden Motion Sensor.
# What it does: Uses `pmset` to disable these features.
# Why it's done: These features are generally irrelevant for an always-on server (Power Nap) or for desktop hardware (Sudden Motion Sensor).
# How it works: Executes `sudo pmset -a powernap 0` and `sudo pmset -a sms 0`.
# Expected result: Power Nap and Sudden Motion Sensor are disabled, potentially saving minor resources.
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
log_action "Starting disabling of miscellaneous services..."

log_action "Disabling Power Nap..."
sudo pmset -a powernap 0
log_action "Disabling Sudden Motion Sensor (SMS)..."
sudo pmset -a sms 0 # Relevant for MacBooks, but harmless to disable on Mini.

log_action "Miscellaneous services disabling script finished."