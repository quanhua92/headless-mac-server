#!/bin/bash

# Script: 00_initial_setup.sh
# -----------------------------------------------------------------------------
# Inputs:
#   - HEADLESS_SERVER_USER: Username for the server setup (Default: current user)
#   - HEADLESS_BASE_DIR: Base directory for server files (Default: /Users/$HEADLESS_SERVER_USER/headless-mac-server)
#
# Outputs:
#   - Creates the base directory and a logs subdirectory.
#   - Sets up a global log file.
#   - Makes other scripts in this directory executable.
#
# What it does:
#   - Sets essential environment variables for user and base directory.
#   - Creates the necessary directory structure for logs and other files.
#   - Establishes a common logging function and main log file.
#   - Ensures all provided shell scripts are executable.
#
# Why it's done:
#   - To prepare the foundational environment for all subsequent setup steps.
#   - To maintain organized logging for troubleshooting.
#
# How it works:
#   - Defines variables, creates directories with `mkdir -p`.
#   - Uses `chown` and `chmod` for permissions.
#   - Defines a `log_action` bash function.
#   - Uses `chmod +x` to set executable permissions on .sh files.
#
# Expected result:
#   - The ~/headless-mac-server directory and ~/headless-mac-server/logs are created.
#   - A setup.log file is created in the logs directory.
#   - Scripts in the ./scripts directory are executable.
# -----------------------------------------------------------------------------
# Important: Run this script first.
# -----------------------------------------------------------------------------

# --- Configuration ---
export HEADLESS_SERVER_USER=${HEADLESS_SERVER_USER:-$(whoami)}
export HEADLESS_BASE_DIR=${HEADLESS_BASE_DIR:-"/Users/$HEADLESS_SERVER_USER/headless-mac-server"} # This is the parent of the 'scripts' dir.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$HEADLESS_BASE_DIR/logs" # Logs will be in the root of headless-mac-server
MAIN_LOG_FILE="$LOG_DIR/setup.log"

# --- Script Name for Logging ---
SCRIPT_NAME=$(basename "$0")

# --- Helper Functions ---
ensure_dir() {
    local dir_path="$1"
    if [ ! -d "$dir_path" ]; then
        echo "Creating directory: $dir_path (User: $HEADLESS_SERVER_USER)"
        mkdir -p "$dir_path"
        # Ensure the base directory itself is owned by the user.
        # If HEADLESS_BASE_DIR is /Users/$HEADLESS_SERVER_USER/headless-mac-server,
        # this chown might need sudo if script is run as another user initially,
        # but typically $HEADLESS_SERVER_USER is $(whoami) so direct chown is fine.
        chown "$HEADLESS_SERVER_USER:staff" "$(dirname "$dir_path")" # Parent of logs
        chown "$HEADLESS_SERVER_USER:staff" "$dir_path"
        chmod 755 "$dir_path"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$SCRIPT_NAME] Created directory: $dir_path" | tee -a "$MAIN_LOG_FILE"
    fi
}

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$SCRIPT_NAME] $1" | tee -a "$MAIN_LOG_FILE"
}

# --- Main Logic ---
echo "Starting script: $SCRIPT_NAME"
echo "Server User: $HEADLESS_SERVER_USER"
echo "Base Directory: $HEADLESS_BASE_DIR"
echo "Script Directory: $SCRIPT_DIR"
echo "Log Directory: $LOG_DIR"

# Create base and log directories
ensure_dir "$HEADLESS_BASE_DIR" # Ensure base directory exists first
ensure_dir "$LOG_DIR"

log_action "Initial setup script started."
log_action "HEADLESS_SERVER_USER set to $HEADLESS_SERVER_USER"
log_action "HEADLESS_BASE_DIR set to $HEADLESS_BASE_DIR"

# Make other scripts in this directory executable
log_action "Making shell scripts in $SCRIPT_DIR executable..."
chmod +x "$SCRIPT_DIR"/*.sh
if [ -d "$SCRIPT_DIR/lib" ]; then
    chmod +x "$SCRIPT_DIR/lib"/*.sh
    log_action "Made scripts in $SCRIPT_DIR/lib executable."
fi
if [ -d "$SCRIPT_DIR/optional_ollama" ]; then
    chmod +x "$SCRIPT_DIR/optional_ollama"/*.sh
    if [ -d "$SCRIPT_DIR/optional_ollama/lib" ]; then
       chmod +x "$SCRIPT_DIR/optional_ollama/lib"/*.sh
       log_action "Made scripts in $SCRIPT_DIR/optional_ollama/lib executable."
    fi
    log_action "Made scripts in $SCRIPT_DIR/optional_ollama executable."
fi


# Create a placeholder for MLX models directory (actual creation in mlx setup script)
# ensure_dir "$HEADLESS_BASE_DIR/mlx_models"
# Create a placeholder for Colima config (if needed)
# ensure_dir "$HEADLESS_BASE_DIR/colima_config"


log_action "Initial setup complete. Main log file at: $MAIN_LOG_FILE"
echo "Script finished: $SCRIPT_NAME"