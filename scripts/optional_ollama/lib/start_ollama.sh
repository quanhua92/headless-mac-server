#!/bin/bash
# Script: start_ollama.sh (Helper for Ollama LaunchDaemon)

# --- Configuration (should be set by the calling LaunchDaemon or environment) ---
HEADLESS_SERVER_USER=${HEADLESS_SERVER_USER:-"$(whoami)"}
HEADLESS_BASE_DIR=${HEADLESS_BASE_DIR:-"/Users/$HEADLESS_SERVER_USER/headless-mac-server"}

LOG_DIR="$HEADLESS_BASE_DIR/logs"
OLLAMA_LOG_FILE="$LOG_DIR/ollama_daemon.log" # Ollama's own logging is usually better
OLLAMA_ERR_FILE="$LOG_DIR/ollama_daemon.err"

mkdir -p "$LOG_DIR"
chown "$HEADLESS_SERVER_USER:staff" "$LOG_DIR"

log_daemon() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [start_ollama] $1" | tee -a "$OLLAMA_LOG_FILE"
}

exec >> "$OLLAMA_LOG_FILE" 2>> "$OLLAMA_ERR_FILE"

log_daemon "start_ollama.sh script initiated by launchd."
log_daemon "User: $(whoami), Home: $HOME"

# Locate Ollama executable
# Ollama is typically installed in /usr/local/bin or via its app bundle symlink
OLLAMA_EXEC=""
if [ -x /usr/local/bin/ollama ]; then
    OLLAMA_EXEC="/usr/local/bin/ollama"
elif [ -x "/Applications/Ollama.app/Contents/Resources/ollama" ]; then # If installed via App
    OLLAMA_EXEC="/Applications/Ollama.app/Contents/Resources/ollama"
elif command -v ollama &>/dev/null; then
    OLLAMA_EXEC=$(command -v ollama)
else
    log_daemon "ERROR: Ollama executable not found. Please ensure Ollama is installed."
    exit 1
fi
log_daemon "Using Ollama executable: $OLLAMA_EXEC"

# Environment variables for Ollama (can be set in the plist)
# OLLAMA_HOST (e.g., 0.0.0.0:11434)
# OLLAMA_MODELS (e.g., /Users/$HEADLESS_SERVER_USER/.ollama/models)
# OLLAMA_KEEP_ALIVE (e.g., "15m" for 15 minutes idle unload)
# OLLAMA_NUM_PARALLEL, OLLAMA_MAX_LOADED_MODELS etc.

log_daemon "Starting Ollama serve..."
# The `ollama serve` command will run in the foreground, managed by launchd.
# Ollama handles its own logging, typically to ~/.ollama/logs or system logs.
# The StandardOutPath/StandardErrorPath in the plist will capture initial messages.
exec "$OLLAMA_EXEC" serve