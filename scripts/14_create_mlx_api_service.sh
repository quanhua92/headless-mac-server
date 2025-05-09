#!/bin/bash

# Script: 14_create_mlx_api_service.sh
# -----------------------------------------------------------------------------
# Inputs:
#   - HEADLESS_SERVER_USER, HEADLESS_BASE_DIR (from environment or defaults)
# Outputs:
#   - Creates a LaunchDaemon plist file for the MLX API server in `/Library/LaunchDaemons/`.
#   - Loads and starts the MLX API server service.
# What it does:
#   Sets up the `mlx-server` (from mlx-community) to run automatically on system boot.
#   The daemon runs as $HEADLESS_SERVER_USER and uses the `start_mlx_server.sh` helper.
# Why it's done:
#   To provide a persistent LLM API endpoint that starts on boot and manages model memory (idle unload).
# How it works:
#   - Ensures `start_mlx_server.sh` (from script 11) exists.
#   - Generates a .plist file, copies it to `/Library/LaunchDaemons/`, sets permissions.
#   - Uses `sudo launchctl load -w` to enable and start the service.
# Expected result:
#   MLX API server service is installed and running. The API should be accessible as configured in
#   `mlx_server_config_example.yaml` (or your customized version).
# -----------------------------------------------------------------------------
# Important: Requires sudo privileges.
# Ensure `mlx-server` is installed and `start_mlx_server.sh` exists (script 11).
# Ensure Python and MLX are installed (script 10).
# -----------------------------------------------------------------------------

# --- Configuration ---
export HEADLESS_SERVER_USER=${HEADLESS_SERVER_USER:-$(whoami)}
export HEADLESS_BASE_DIR=${HEADLESS_BASE_DIR:-"/Users/$HEADLESS_SERVER_USER/headless-mac-server"}
LOG_DIR="$HEADLESS_BASE_DIR/logs"
MAIN_LOG_FILE="$LOG_DIR/setup.log"
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LIB_DIR="$SCRIPT_DIR/lib"
PLIST_LABEL_MLX="com.headlessmac.mlx.api.service" # Customizable label
PLIST_FILENAME_MLX="$PLIST_LABEL_MLX.plist"
LAUNCHDAEMONS_DIR="/Library/LaunchDaemons"
TARGET_PLIST_PATH_MLX="$LAUNCHDAEMONS_DIR/$PLIST_FILENAME_MLX"
START_MLX_SCRIPT="$LIB_DIR/start_mlx_server.sh"

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$SCRIPT_NAME] $1" | tee -a "$MAIN_LOG_FILE"
}

# --- Ensure helper script exists ---
if [ ! -f "$START_MLX_SCRIPT" ]; then
    log_action "ERROR: $START_MLX_SCRIPT not found. Please run script 11_setup_mlx_server_app.sh first."
    exit 1
else
    chmod +x "$START_MLX_SCRIPT" # Ensure it's executable
    chown "$HEADLESS_SERVER_USER:staff" "$START_MLX_SCRIPT"
    log_action "$START_MLX_SCRIPT found and permissions set."
fi

# --- Main Logic ---
log_action "Starting MLX API service creation..."

# Create the .plist content for MLX server
# Note: The actual mlx-server logs are handled by start_mlx_server.sh
PLIST_CONTENT_MLX="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL_MLX</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$START_MLX_SCRIPT</string>
    </array>
    <key>UserName</key>
    <string>$HEADLESS_SERVER_USER</string>
    <key>GroupName</key>
    <string>staff</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict> <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
    </dict>
    <key>StandardOutPath</key>
    <string>$HEADLESS_BASE_DIR/logs/mlx_launchd.out.log</string>
    <key>StandardErrorPath</key>
    <string>$HEADLESS_BASE_DIR/logs/mlx_launchd.err.log</string>
    <key>WorkingDirectory</key>
    <string>$HEADLESS_BASE_DIR</string> <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>/Users/$HEADLESS_SERVER_USER</string>
        <key>PATH</key> <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        <key>HEADLESS_SERVER_USER</key>
        <string>$HEADLESS_SERVER_USER</string>
        <key>HEADLESS_BASE_DIR</key>
        <string>$HEADLESS_BASE_DIR</string>
        </dict>
    <key>ProcessType</key>
    <string>Background</string>
</dict>
</plist>"

TEMP_PLIST_PATH_MLX="/tmp/$PLIST_FILENAME_MLX"
echo "$PLIST_CONTENT_MLX" > "$TEMP_PLIST_PATH_MLX"
log_action "Temporary MLX plist created at $TEMP_PLIST_PATH_MLX"

# Unload existing service if it's running (for updates)
if [ -f "$TARGET_PLIST_PATH_MLX" ]; then
    log_action "Service $PLIST_LABEL_MLX already exists. Unloading current version..."
    sudo launchctl unload "$TARGET_PLIST_PATH_MLX" 2>/dev/null || true
fi

# Copy plist to LaunchDaemons
log_action "Copying $TEMP_PLIST_PATH_MLX to $TARGET_PLIST_PATH_MLX..."
sudo cp "$TEMP_PLIST_PATH_MLX" "$TARGET_PLIST_PATH_MLX"
rm "$TEMP_PLIST_PATH_MLX"

# Set permissions for the plist file
sudo chown root:wheel "$TARGET_PLIST_PATH_MLX"
sudo chmod 644 "$TARGET_PLIST_PATH_MLX"
log_action "Permissions set for $TARGET_PLIST_PATH_MLX (owner: root:wheel, mode: 644)."

# Load the service
log_action "Loading and starting service $PLIST_LABEL_MLX..."
sudo launchctl load -w "$TARGET_PLIST_PATH_MLX"
if [ $? -eq 0 ]; then
    log_action "Service $PLIST_LABEL_MLX loaded successfully."
    log_action "It should start the MLX API server shortly. Check logs at:"
    log_action "  Daemon logs: $HEADLESS_BASE_DIR/logs/mlx_launchd.*.log"
    log_action "  start_mlx_server.sh logs: $HEADLESS_BASE_DIR/logs/mlx_server.log / .err"
    log_action "Ensure your $HEADLESS_BASE_DIR/config_templates/mlx_server_config_example.yaml (or your actual config file) is correctly set up."
else
    log_action "ERROR: Failed to load service $PLIST_LABEL_MLX."
    log_action "Check for errors above or in system logs: log show --predicate 'process == \"launchd\"' --last 1h"
    exit 1
fi

log_action "MLX API service creation script finished."
log_action "To check status: sudo launchctl list | grep $PLIST_LABEL_MLX"
log_action "API should be available at http://<your_mac_ip>:<port_from_config> (e.g., http://localhost:8080 by default)."