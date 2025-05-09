#!/bin/bash

# Script: 12_install_colima_docker.sh
# -----------------------------------------------------------------------------
# Inputs: None (assumes Homebrew is installed and in PATH)
# Outputs: Installs Colima and Docker CLI.
# What it does: Uses `brew` to install `colima` and `docker`.
# Why it's done: Colima provides a container runtime (alternative to Docker Desktop) suitable for headless macOS. Docker CLI is needed to interact with it.
# How it works: `brew install colima docker`.
# Expected result: `colima` and `docker` commands are available.
# -----------------------------------------------------------------------------
# Important: Requires Homebrew. Assumes `brew` is in PATH.
# Internet connection needed for downloads.
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

# Function to ensure brew is in PATH
ensure_brew_path() {
    if ! command -v brew &>/dev/null; then
        log_action "brew command not found. Attempting to set PATH for Homebrew."
        if [ -x /opt/homebrew/bin/brew ]; then
            export PATH="/opt/homebrew/bin:$PATH"
            log_action "/opt/homebrew/bin added to PATH for this session."
        elif [ -x /usr/local/bin/brew ]; then
            export PATH="/usr/local/bin:$PATH"
            log_action "/usr/local/bin added to PATH for this session."
        else
            log_action "ERROR: brew command not found and Homebrew not in expected locations. Please install Homebrew or fix PATH."
            exit 1
        fi

        if ! command -v brew &>/dev/null; then
             log_action "ERROR: Failed to make brew command available. Exiting."
             exit 1
        fi
    fi
}

# --- Main Logic ---
log_action "Starting Colima and Docker CLI installation..."

ensure_brew_path

# Install Colima
if command -v colima &>/dev/null; then
    log_action "Colima is already installed."
    colima version 2>&1 | tee -a "$MAIN_LOG_FILE"
else
    log_action "Installing Colima using Homebrew..."
    brew install colima
    if [ $? -ne 0 ]; then
        log_action "ERROR: Failed to install Colima."
        exit 1
    fi
    log_action "Colima installed successfully."
    colima version 2>&1 | tee -a "$MAIN_LOG_FILE"
fi

# Install Docker CLI (docker, docker-buildx, docker-compose)
# The `docker` formula usually includes the CLI and related tools.
if command -v docker &>/dev/null; then
    log_action "Docker CLI is already installed."
    docker --version 2>&1 | tee -a "$MAIN_LOG_FILE"
else
    log_action "Installing Docker CLI using Homebrew..."
    brew install docker
    if [ $? -ne 0 ]; then
        log_action "ERROR: Failed to install Docker CLI."
        exit 1
    fi
    log_action "Docker CLI installed successfully."
    docker --version 2>&1 | tee -a "$MAIN_LOG_FILE"
fi

log_action "Colima and Docker CLI installation script finished."
log_action "Next steps: Create Colima service (13_create_colima_service.sh) to start it automatically."