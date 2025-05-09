#!/bin/bash

# Script: 05_disable_auto_updates.sh
# -----------------------------------------------------------------------------
# Inputs: None
# Outputs: Disables automatic macOS software updates.
# What it does: Modifies system preferences for Software Update.
# Why it's done: To prevent unexpected server reboots or changes. Updates should be applied manually during maintenance windows.
# How it works: Uses `sudo defaults write` to change SoftwareUpdate settings.
# Expected result: The system will not automatically check for or download macOS updates.
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
log_action "Starting automatic updates disabling..."

log_action "Disabling automatic check for updates..."
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
log_action "Disabling automatic download of updates..."
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
log_action "Disabling automatic app updates from App Store..."
sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool false
log_action "Disabling automatic macOS updates installation..."
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool false
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool false

# Optional: Disable automatic installation of XProtect, MRT, and Gatekeeper updates
# These are security updates, consider carefully if you want to disable them.
# For a server, manual control might be preferred, but security is also key.
# log_action "Disabling automatic security data updates (XProtect, MRT)..."
# sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false

log_action "Automatic updates settings changed. Reboot might be needed for all settings to fully apply or check System Settings."
log_action "Automatic updates disabling script finished."