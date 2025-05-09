#!/bin/bash

# Script: start_colima.sh (Helper for Colima LaunchDaemon)
# -----------------------------------------------------------------------------
# This script is executed by the Colima launch daemon to start Colima.
# -----------------------------------------------------------------------------

# --- Configuration (should be set by the calling LaunchDaemon or environment) ---
# These defaults can be overridden by environment variables set in the plist
HEADLESS_SERVER_USER=${HEADLESS_SERVER_USER:-"$(whoami)"} # Should match plist UserName
HEADLESS_BASE_DIR=${HEADLESS_BASE_DIR:-"/Users/$HEADLESS_SERVER_USER/headless-mac-server"}

LOG_DIR="$HEADLESS_BASE_DIR/logs"
COLIMA_LOG_FILE="$LOG_DIR/colima_daemon.log"
COLIMA_ERR_FILE="$LOG_DIR/colima_daemon.err"

# Colima VM settings (configurable via environment variables in plist)
COLIMA_CPU=${COLIMA_CPU:-4}
COLIMA_MEM=${COLIMA_MEM:-8} # In GiB
COLIMA_DISK=${COLIMA_DISK:-60} # In GiB
COLIMA_VM_TYPE=${COLIMA_VM_TYPE:-"vz"} # Use 'vz' for Apple Silicon with macOS Sonoma+ for better performance
COLIMA_MOUNT_TYPE=${COLIMA_MOUNT_TYPE:-"virtiofs"} # Or 'sshfs' or 'reverse-sshfs'
COLIMA_PROFILE_NAME=${COLIMA_PROFILE_NAME:-"headless-mac-server"} # Custom profile name

# Ensure log directory exists
mkdir -p "$LOG_DIR"
chown "$HEADLESS_SERVER_USER:staff" "$LOG_DIR" # Ensure user owns log dir

log_daemon() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [start_colima] $1" | tee -a "$COLIMA_LOG_FILE"
}

# Redirect stdout and stderr for the whole script
exec >> "$COLIMA_LOG_FILE" 2>> "$COLIMA_ERR_FILE"

log_daemon "start_colima.sh script started."
log_daemon "User: $(whoami), Home: $HOME"
log_daemon "HEADLESS_SERVER_USER: $HEADLESS_SERVER_USER, HEADLESS_BASE_DIR: $HEADLESS_BASE_DIR"
log_daemon "Colima Profile: $COLIMA_PROFILE_NAME, CPU: $COLIMA_CPU, Mem: $COLIMA_MEM GB, Disk: $COLIMA_DISK GB, VM: $COLIMA_VM_TYPE, Mount: $COLIMA_MOUNT_TYPE"

# Locate colima executable
# Prefer Homebrew paths
COLIMA_EXEC=""
if [ -x /opt/homebrew/bin/colima ]; then
    COLIMA_EXEC="/opt/homebrew/bin/colima"
elif [ -x /usr/local/bin/colima ]; then
    COLIMA_EXEC="/usr/local/bin/colima"
elif command -v colima &>/dev/null; then
    COLIMA_EXEC=$(command -v colima)
else
    log_daemon "ERROR: Colima executable not found. Please ensure Colima is installed and in PATH."
    exit 1
fi
log_daemon "Using Colima executable: $COLIMA_EXEC"

# Check if Docker CLI is installed
if ! command -v docker &>/dev/null; then
    log_daemon "ERROR: Docker CLI not found. Please install docker (brew install docker)."
    exit 1
fi

# Check if Colima profile is already running
if "$COLIMA_EXEC" status --profile "$COLIMA_PROFILE_NAME" 2>/dev/null | grep -q "Running"; then
    log_daemon "Colima profile '$COLIMA_PROFILE_NAME' is already running."
    # Ensure Docker context is set correctly for this profile
    if ! docker context show | grep -q "$COLIMA_PROFILE_NAME"; then
         log_daemon "Docker context not set to $COLIMA_PROFILE_NAME. Attempting to use it."
         "$COLIMA_EXEC" docker-env --profile "$COLIMA_PROFILE_NAME" > /tmp/colima_env.sh
         source /tmp/colima_env.sh
         rm /tmp/colima_env.sh
    fi
    exit 0
fi

# Check if profile exists but is stopped
if "$COLIMA_EXEC" list | grep -q "$COLIMA_PROFILE_NAME"; then
    log_daemon "Colima profile '$COLIMA_PROFILE_NAME' exists but is stopped. Starting it..."
    "$COLIMA_EXEC" start --profile "$COLIMA_PROFILE_NAME" \
        --cpu "$COLIMA_CPU" \
        --memory "$COLIMA_MEM" \
        --disk "$COLIMA_DISK" \
        --vm-type "$COLIMA_VM_TYPE" \
        --mount-type "$COLIMA_MOUNT_TYPE" \
        --edit=false # Prevent opening editor if config exists
else
    log_daemon "Colima profile '$COLIMA_PROFILE_NAME' does not exist. Creating and starting it..."
    "$COLIMA_EXEC" start --profile "$COLIMA_PROFILE_NAME" \
        --cpu "$COLIMA_CPU" \
        --memory "$COLIMA_MEM" \
        --disk "$COLIMA_DISK" \
        --vm-type "$COLIMA_VM_TYPE" \
        --mount-type "$COLIMA_MOUNT_TYPE" \
        --arch x86_64,aarch64 # Enable rosetta for x86_64 images on ARM
        # Additional potentially useful flags:
        # --mount /path/on/host:/path/in/vm:w # For custom mounts
        # --dns 8.8.8.8,1.1.1.1 # Custom DNS
fi

if [ $? -ne 0 ]; then
    log_daemon "ERROR: Failed to start Colima profile '$COLIMA_PROFILE_NAME'."
    exit 1
fi

log_daemon "Colima profile '$COLIMA_PROFILE_NAME' started successfully."

# Wait for Docker to become available (Colima handles Docker socket activation)
log_daemon "Waiting for Docker daemon to become available via Colima profile '$COLIMA_PROFILE_NAME'..."
# Set docker context to colima profile
# This needs to be done in the user's environment, not just this script.
# The daemon ensures Colima runs; user must `docker context use colima-$COLIMA_PROFILE_NAME` or setup DOCKER_HOST.
# However, `colima start` typically makes its Docker socket the default for subsequent `docker` commands if no context is set.

# For the service, just check if `docker info` works with the colima context
DOCKER_CONTEXT_CMD="$COLIMA_EXEC docker-env --profile $COLIMA_PROFILE_NAME"
log_daemon "Setting up Docker environment for check: $DOCKER_CONTEXT_CMD"
eval $($DOCKER_CONTEXT_CMD)

for i in {1..60}; do
    if docker info &>/dev/null; then
        log_daemon "Docker daemon is now responsive via Colima profile '$COLIMA_PROFILE_NAME'."
        # Setup docker context for the user (this is tricky from a daemon script)
        # The user should ideally run `colima start` once manually to set up contexts,
        # or set DOCKER_CONTEXT env var.
        log_daemon "To use this Docker instance from your terminal, you might need to run:"
        log_daemon "export DOCKER_CONTEXT=colima-$COLIMA_PROFILE_NAME"
        log_daemon "or ensure Colima has set up the Docker socket symlink correctly."
        exit 0
    fi
    log_daemon "Still waiting for Docker daemon... ($i seconds elapsed)"
    sleep 1
done

log_daemon "ERROR: Docker daemon did not become responsive within the timeout period for profile '$COLIMA_PROFILE_NAME'."
log_daemon "Try checking 'colima status --profile $COLIMA_PROFILE_NAME' and 'colima logs --profile $COLIMA_PROFILE_NAME'."
exit 1