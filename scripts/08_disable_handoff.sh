#!/bin/bash

# Script: 08_disable_handoff.sh
# -----------------------------------------------------------------------------
# Inputs:
#   - HEADLESS_SERVER_USER: The user for whom to disable Handoff. (Default: current user)
# Outputs: Disables Handoff for the specified user.
# What it does: Modifies user preferences related to Handoff.
# Why it's done: Handoff is irrelevant for a headless server and might consume minor resources.
# How it works: Uses `defaults write` for user-specific ByHost preferences.
# Expected result: Handoff feature is disabled for the user.
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
log_action "Starting Handoff disabling for user $HEADLESS_SERVER_USER..."

# Define preference paths. Note that the exact path might vary slightly across macOS versions.
# These are common paths for Handoff settings.
PREF_DOMAIN_CORESUD="com.apple.coreservices.useractivityd"
USER_PREFS_BYHOST_DIR="/Users/$HEADLESS_SERVER_USER/Library/Preferences/ByHost"

disable_handoff_prefs() {
    local user_to_target="$1"
    local byhost_dir="/Users/$user_to_target/Library/Preferences/ByHost"

    if [ ! -d "$byhost_dir" ]; then
        log_action "WARNING: ByHost preferences directory not found for user $user_to_target. Skipping Handoff defaults."
        return
    fi

    # Find the specific plist files for useractivityd as their names include a UUID
    local target_plist_advertising=$(find "$byhost_dir" -name "${PREF_DOMAIN_CORESUD}.*.plist" -print -quit)
    # If not found, we might try writing to the general domain, but it's less reliable for ByHost.

    log_action "Setting ActivityAdvertisingAllowed to false for user $user_to_target..."
    if [ "$(whoami)" == "$user_to_target" ]; then
        defaults write "$PREF_DOMAIN_CORESUD" ActivityAdvertisingAllowed -bool false
        defaults write "$PREF_DOMAIN_CORESUD" ActivityReceivingAllowed -bool false
    else
        sudo -u "$user_to_target" defaults write "$PREF_DOMAIN_CORESUD" ActivityAdvertisingAllowed -bool false
        sudo -u "$user_to_target" defaults write "$PREF_DOMAIN_CORESUD" ActivityReceivingAllowed -bool false
    fi
    log_action "Handoff advertising and receiving preferences set for $user_to_target."
}

disable_handoff_prefs "$HEADLESS_SERVER_USER"

# Additionally, ensure no "Allow Handoff" in System Settings (this is a global setting often)
# This is typically controlled by:
# sudo defaults write /Library/Preferences/com.apple.coreservices.useractivityd.plist ActivityAdvertisingAllowed -bool false
# sudo defaults write /Library/Preferences/com.apple.coreservices.useractivityd.plist ActivityReceivingAllowed -bool false
# However, these global plists may not exist or be used on all systems. The user-specific ones are more direct.

log_action "Handoff disabling script finished. A reboot or re-login might be needed for full effect."