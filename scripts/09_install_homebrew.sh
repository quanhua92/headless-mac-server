#!/bin/bash

# Script: 09_install_homebrew.sh
# -----------------------------------------------------------------------------
# Inputs: None
# Outputs: Installs Homebrew if not already present.
# What it does: Checks for `brew` command, if not found, downloads and runs the official Homebrew installation script.
# Why it's done: Homebrew is a package manager for macOS, essential for installing tools like Python, Colima, Docker.
# How it works: Executes the Homebrew installation script from raw.githubusercontent.com.
# Expected result: Homebrew is installed and the `brew` command is available in the current session's PATH (or a new session).
# -----------------------------------------------------------------------------
# Important: This script will download and execute a script from the internet.
# It may ask for your sudo password during installation.
# Ensure you are comfortable with Homebrew's installation process.
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
log_action "Starting Homebrew installation check..."

if command -v brew &>/dev/null; then
    log_action "Homebrew is already installed."
    brew --version | tee -a "$MAIN_LOG_FILE"
else
    log_action "Homebrew not found. Attempting to install Homebrew..."
    log_action "This will download and execute the official Homebrew installation script."
    read -p "Proceed with Homebrew installation? (yes/NO): " confirmation
    if [[ "$confirmation" == "yes" ]]; then
        # Run the Homebrew installer
        # Ensure curl is available
        if ! command -v curl &> /dev/null; then
            log_action "ERROR: curl is not installed. Cannot download Homebrew installer."
            exit 1
        fi
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        if [ $? -ne 0 ]; then
            log_action "ERROR: Homebrew installation failed. Please check the output above."
            exit 1
        fi
        log_action "Homebrew installation script finished."

        # Add Homebrew to PATH for the current session and recommend adding to shell profile
        # For Apple Silicon Macs, Homebrew is typically in /opt/homebrew
        if [ -x /opt/homebrew/bin/brew ]; then
            log_action "Adding /opt/homebrew/bin to PATH for current session."
            export PATH="/opt/homebrew/bin:$PATH"
            BREW_PATH_MSG="Please add Homebrew to your shell configuration file (e.g., ~/.zshrc, ~/.bash_profile):\n"
            BREW_PATH_MSG+="  echo 'eval \"\$(/opt/homebrew/bin/brew shellenv)\"' >> ~/.zshrc  # For zsh\n"
            BREW_PATH_MSG+="  eval \"\$(/opt/homebrew/bin/brew shellenv)\""
            log_action "$BREW_PATH_MSG"
            echo -e "$BREW_PATH_MSG" # Also to console
        elif [ -x /usr/local/bin/brew ]; then # Intel Macs
             log_action "Adding /usr/local/bin to PATH for current session."
            export PATH="/usr/local/bin:$PATH"
            BREW_PATH_MSG="Please add Homebrew to your shell configuration file (e.g., ~/.zshrc, ~/.bash_profile):\n"
            BREW_PATH_MSG+="  echo 'eval \"\$((/usr/local/bin/brew shellenv))\"' >> ~/.zshrc # For zsh\n"
            BREW_PATH_MSG+="  eval \"\$((/usr/local/bin/brew shellenv))\""
            log_action "$BREW_PATH_MSG"
            echo -e "$BREW_PATH_MSG"
        else
            log_action "WARNING: Homebrew installed, but brew command not found in expected locations. Manual PATH adjustment may be needed."
        fi

        if command -v brew &>/dev/null; then
            log_action "Homebrew installed successfully."
            brew --version | tee -a "$MAIN_LOG_FILE"
        else
            log_action "ERROR: Homebrew installation seems complete but 'brew' command is not available. Check PATH."
            exit 1
        fi
    else
        log_action "Homebrew installation skipped by user."
        exit 1 # Exit if Homebrew is required by subsequent scripts and user skips.
    fi
fi

log_action "Homebrew setup script finished."