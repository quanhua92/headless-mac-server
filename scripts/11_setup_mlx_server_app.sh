#!/bin/bash

# Script: 11_setup_mlx_server_app.sh
# -----------------------------------------------------------------------------
# Inputs:
#   - HEADLESS_BASE_DIR: Base directory for server files.
# Outputs:
#   - Installs `mlx-server` (from mlx-community).
#   - Creates a directory for MLX models (`$HEADLESS_BASE_DIR/mlx_models`).
#   - Creates an example `mlx_server_config.yaml` in `$HEADLESS_BASE_DIR/config_templates`.
#   - Creates the `start_mlx_server.sh` helper script in `scripts/lib/`.
# What it does:
#   Sets up the environment for running an MLX API server using `mlx-community/mlx-server`.
#   This includes installing the server, preparing model storage, and creating a startup script.
# Why it's done:
#   To provide an API endpoint for LLM inference using MLX, with support for model unloading on idle.
# How it works:
#   - `pip3 install mlx-server`.
#   - `mkdir` for model directory.
#   - Generates an example config file and the `start_mlx_server.sh` script.
# Expected result:
#   `mlx-server` is installed. Directories and helper scripts are ready for service configuration.
#   User can download models into `mlx_models` and configure `mlx_server_config.yaml`.
# -----------------------------------------------------------------------------
# Important: Requires Python 3 and pip3 with MLX already installed.
# Internet connection needed for `pip3 install mlx-server`.
# -----------------------------------------------------------------------------

# --- Configuration ---
export HEADLESS_SERVER_USER=${HEADLESS_SERVER_USER:-$(whoami)}
export HEADLESS_BASE_DIR=${HEADLESS_BASE_DIR:-"/Users/$HEADLESS_SERVER_USER/headless-mac-server"}
LOG_DIR="$HEADLESS_BASE_DIR/logs"
MAIN_LOG_FILE="$LOG_DIR/setup.log"
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LIB_DIR="$SCRIPT_DIR/lib"
CONFIG_TEMPLATE_DIR="$HEADLESS_BASE_DIR/config_templates" # Will be created if not exists
MLX_MODELS_DIR="$HEADLESS_BASE_DIR/mlx_models"

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$SCRIPT_NAME] $1" | tee -a "$MAIN_LOG_FILE"
}

ensure_dir() {
    local dir_path="$1"
    if [ ! -d "$dir_path" ]; then
        log_action "Creating directory: $dir_path"
        mkdir -p "$dir_path"
        chown "$HEADLESS_SERVER_USER:staff" "$dir_path"
        chmod 755 "$dir_path"
    fi
}

# --- Main Logic ---
log_action "Starting MLX Server App setup..."

ensure_dir "$LIB_DIR"
ensure_dir "$CONFIG_TEMPLATE_DIR"
ensure_dir "$MLX_MODELS_DIR"

# Install mlx-server
log_action "Installing mlx-server from mlx-community using pip3..."
pip3 install mlx-server --prefer-binary
if [ $? -ne 0 ]; then
    log_action "ERROR: Failed to install mlx-server."
    exit 1
fi
log_action "mlx-server installed successfully."
mlx-server --version >> "$MAIN_LOG_FILE" 2>&1

# Create example mlx_server_config.yaml
EXAMPLE_MLX_CONFIG_PATH="$CONFIG_TEMPLATE_DIR/mlx_server_config_example.yaml"
log_action "Creating example mlx-server config at $EXAMPLE_MLX_CONFIG_PATH..."
cat > "$EXAMPLE_MLX_CONFIG_PATH" << EOL
# Example mlx_server_config.yaml
# Documentation: https://github.com/mlx-community/mlx-server
# List of models to serve. You can specify multiple models.
models:
  - model: "mlx-community/Nous-Hermes-2-Mistral-7B-DPO-4bit-MLX" # Example model from Hugging Face
    # id: "hermes-7b-dpo" # Optional: custom model ID for API endpoint, otherwise derived from path
    # tokenizer: "mlx-community/Nous-Hermes-2-Mistral-7B-DPO-4bit-MLX" # Optional: if different from model path
    # adapter_file: "/path/to/adapter.npz" # Optional: for LoRA adapters

  # - model: "/Users/$HEADLESS_SERVER_USER/headless-mac-server/mlx_models/your_local_model_dir_mlx_format"
  #   id: "my-local-model"

# Server configuration
host: "0.0.0.0" # Listen on all interfaces
port: 8080
# Important for your requirement: Unload model if idle for X seconds. Default: no unload.
unload_idle_seconds: 900 # 15 minutes (15 * 60 = 900), 600 for 10 minutes
# max_model_ συγκεκριμένα: (Optional) Max number of models to keep in memory.
# max_tokens: (Optional) Default max tokens for generation.
# temp: (Optional) Default temperature for generation.
# log_level: "INFO" # "DEBUG", "INFO", "WARNING", "ERROR"
# api_keys: # Optional: list of API keys for authentication
#   - "your-secret-api-key-1"
#   - "your-secret-api-key-2"
EOL
chown "$HEADLESS_SERVER_USER:staff" "$EXAMPLE_MLX_CONFIG_PATH"
log_action "Example config created. Customize it with your models and desired settings."
log_action "Models should be placed in $MLX_MODELS_DIR or specify full paths/HF identifiers."

# Create start_mlx_server.sh helper script
START_MLX_SERVER_SCRIPT="$LIB_DIR/start_mlx_server.sh"
log_action "Creating MLX server startup script at $START_MLX_SERVER_SCRIPT..."
cat > "$START_MLX_SERVER_SCRIPT" << EOL
#!/bin/bash

# Startup script for mlx-server
# This script will be called by the launchd service.

# --- Configuration ---
SERVER_USER="${HEADLESS_SERVER_USER}" # Inherited from parent script or set if run directly
BASE_DIR="${HEADLESS_BASE_DIR}"     # Inherited from parent script or set if run directly
CONFIG_FILE="\$BASE_DIR/config_templates/mlx_server_config_example.yaml" # Default config, user should copy & edit
LOG_FILE="\$BASE_DIR/logs/mlx_server.log"
ERR_LOG_FILE="\$BASE_DIR/logs/mlx_server.err"

# Ensure log directory exists (it should, but good practice)
mkdir -p "\$(dirname "\$LOG_FILE")"
chown "\$SERVER_USER:staff" "\$(dirname "\$LOG_FILE")"

echo "Starting MLX Server: \$(date)" >> "\$LOG_FILE"
echo "User: \$(whoami)" >> "\$LOG_FILE"
echo "Using config: \$CONFIG_FILE" >> "\$LOG_FILE"

# Path to mlx-server (assuming it's in Python's bin directory, adjust if using venv)
# First, try to find Homebrew's Python bin dir if it exists
PYTHON_BIN_DIR=""
if [ -x /opt/homebrew/bin/python3 ]; then
    PYTHON_BIN_DIR="/opt/homebrew/bin"
elif [ -x /usr/local/bin/python3 ]; then # Older Intel Homebrew
    PYTHON_BIN_DIR="/usr/local/bin"
elif command -v python3 &>/dev/null; then # System or other Python3
    PYTHON_BIN_DIR="\$(dirname \$(command -v python3))"
fi

MLX_SERVER_EXEC="mlx-server"
if [ -n "\$PYTHON_BIN_DIR" ] && [ -x "\$PYTHON_BIN_DIR/mlx-server" ]; then
    MLX_SERVER_EXEC="\$PYTHON_BIN_DIR/mlx-server"
elif ! command -v mlx-server &>/dev/null; then
    echo "ERROR: mlx-server command not found. Ensure it is installed and in PATH." >> "\$ERR_LOG_FILE"
    exit 1
fi

echo "mlx-server executable: \$MLX_SERVER_EXEC" >> "\$LOG_FILE"

# Check if config file exists
if [ ! -f "\$CONFIG_FILE" ]; then
    echo "ERROR: MLX Server config file not found at \$CONFIG_FILE" >> "\$ERR_LOG_FILE"
    echo "Please create it based on the example in config_templates." >> "\$ERR_LOG_FILE"
    exit 1
fi

# Run mlx-server
# The --preload-models flag can be added if you want to load all models at startup
# For memory release on idle, ensure 'unload_idle_seconds' is set in the YAML config.
exec "\$MLX_SERVER_EXEC" --config-path "\$CONFIG_FILE" >> "\$LOG_FILE" 2>> "\$ERR_LOG_FILE"
EOL
chmod +x "$START_MLX_SERVER_SCRIPT"
chown "$HEADLESS_SERVER_USER:staff" "$START_MLX_SERVER_SCRIPT"
log_action "MLX server startup script created."
log_action "IMPORTANT: Review and customize '$EXAMPLE_MLX_CONFIG_PATH'."
log_action "You might want to copy it to '$HEADLESS_BASE_DIR/mlx_server_config.yaml' and adjust the path in '$START_MLX_SERVER_SCRIPT'."

log_action "MLX Server App setup script finished."