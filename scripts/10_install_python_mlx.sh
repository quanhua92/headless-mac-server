#!/bin/bash

# Script: 10_install_python_mlx.sh
# -----------------------------------------------------------------------------
# Inputs: None (assumes Homebrew is installed and in PATH)
# Outputs: Installs Python (via Homebrew) and MLX libraries (`mlx`, `mlx-lm`).
# What it does: Uses `brew` to install Python 3 and `pip3` to install MLX packages.
# Why it's done: To provide the necessary Python environment for running MLX-based LLM models.
# How it works: `brew install python`, `pip3 install mlx mlx-lm`.
# Expected result: Python 3 and the core MLX libraries are installed.
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
log_action "Starting Python and MLX installation..."

ensure_brew_path

# Install Python using Homebrew
if command -v python3 &>/dev/null && python3 -V | grep -q "3\."; then
    log_action "Python 3 already installed."
    python3 -V 2>&1 | tee -a "$MAIN_LOG_FILE"
else
    log_action "Installing Python 3 using Homebrew..."
    brew install python
    if [ $? -ne 0 ]; then
        log_action "ERROR: Failed to install Python 3 via Homebrew."
        exit 1
    fi
    log_action "Python 3 installed successfully."
    python3 -V 2>&1 | tee -a "$MAIN_LOG_FILE"
fi

# Ensure pip3 is available
if ! command -v pip3 &>/dev/null; then
    log_action "ERROR: pip3 command not found even after Python 3 installation. Check Python installation."
    exit 1
fi

# Install MLX libraries
log_action "Installing MLX libraries (mlx, mlx-lm) using pip3..."
# Consider using a virtual environment for production setups
# For simplicity here, installing globally for the Homebrew Python
pip3 install mlx mlx-lm --prefer-binary
if [ $? -ne 0 ]; then
    log_action "ERROR: Failed to install MLX libraries."
    exit 1
fi
log_action "MLX libraries installed successfully."

# Verify installation by trying to import
log_action "Verifying MLX installation..."
python3 -c "import mlx; import mlx.core; import mlx.nn; import mlx.optimizers; import mlx_lm; print('MLX and MLX-LM imported successfully!')" >> "$MAIN_LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log_action "ERROR: Failed to verify MLX installation by importing."
    # tail -n 5 "$MAIN_LOG_FILE" # Show last few lines of log which might contain Python error
else
    log_action "MLX and MLX-LM import verification successful."
fi

log_action "Python and MLX installation script finished."