#!/bin/bash
# Script: 15_setup_ollama.sh (Optional)

# --- Configuration ---
export HEADLESS_SERVER_USER=${HEADLESS_SERVER_USER:-$(whoami)}
export HEADLESS_BASE_DIR=${HEADLESS_BASE_DIR:-"/Users/$HEADLESS_SERVER_USER/headless-mac-server"}
LOG_DIR="$HEADLESS_BASE_DIR/logs"
MAIN_LOG_FILE="$LOG_DIR/setup.log" # Appends to the main log
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Should be .../optional_ollama

LIB_DIR="$SCRIPT_DIR/lib"
PLIST_LABEL_OLLAMA="com.headlessmac.ollama.service"
PLIST_FILENAME_OLLAMA="$PLIST_LABEL_OLLAMA.plist"
LAUNCHDAEMONS_DIR="/Library/LaunchDaemons"
TARGET_PLIST_PATH_OLLAMA="$LAUNCHDAEMONS_DIR/$PLIST_FILENAME_OLLAMA"
START_OLLAMA_SCRIPT="$LIB_DIR/start_ollama.sh"

# Ollama specific ENV VARS for the plist
export OLLAMA_HOST=${OLLAMA_HOST:-"0.0.0.0:11434"}
export OLLAMA_MODELS_DIR=${OLLAMA_MODELS_DIR:-"/Users/$HEADLESS_SERVER_USER/.ollama/models"}
export OLLAMA_KEEP_ALIVE=${OLLAMA_KEEP_ALIVE:-"15m"} # Model idle timeout
export OLLAMA_NUM_PARALLEL=${OLLAMA_NUM_PARALLEL:-""} # Default based on cores
export OLLAMA_MAX_LOADED_MODELS=${OLLAMA_MAX_LOADED_MODELS:-"1"}

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$SCRIPT_NAME] $1" | tee -a "$MAIN_LOG_FILE"
}

# --- Main Logic ---
log_action "Starting optional Ollama service creation..."

# 1. Ensure Ollama is installed
if ! command -v ollama &>/dev/null && [ ! -x "/Applications/Ollama.app/Contents/Resources/ollama" ] && [ ! -x "/usr/local/bin/ollama" ]; then
    log_action "Ollama command not found. Please install Ollama first from https://ollama.com/"
    log_action "You can download it and run 'ollama version' to confirm installation."
    exit 1
else
    log_action "Ollama installation found."
fi

# 2. Ensure start_ollama.sh helper script exists
ensure_dir "$LIB_DIR" # Ensure lib dir within optional_ollama exists
if [ ! -f "$START_OLLAMA_SCRIPT" ]; then
    log_action "ERROR: $START_OLLAMA_SCRIPT not found. Please create it first."
    exit 1
else
    chmod +x "$START_OLLAMA_SCRIPT"
    chown "$HEADLESS_SERVER_USER:staff" "$START_OLLAMA_SCRIPT"
    log_action "$START_OLLAMA_SCRIPT found and permissions set."
fi

# 3. Create Ollama .ollama models directory if it doesn't exist
OLLAMA_USER_HOME_MODELS_DIR_RESOLVED=$(eval echo "$OLLAMA_MODELS_DIR") # Expand ~ if used
if [ ! -d "$OLLAMA_USER_HOME_MODELS_DIR_RESOLVED" ]; then
    log_action "Creating Ollama models directory at $OLLAMA_USER_HOME_MODELS_DIR_RESOLVED for user $HEADLESS_SERVER_USER..."
    sudo -u "$HEADLESS_SERVER_USER" mkdir -p "$OLLAMA_USER_HOME_MODELS_DIR_RESOLVED"
    if [ $? -ne 0 ]; then
        log_action "ERROR: Failed to create Ollama models directory. Check permissions."
    fi
fi


# 4. Create plist
PLIST_CONTENT_OLLAMA="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL_OLLAMA</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$START_OLLAMA_SCRIPT</string>
    </array>
    <key>UserName</key>
    <string>$HEADLESS_SERVER_USER</string>
    <key>GroupName</key>
    <string>staff</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
    </dict>
    <key>StandardOutPath</key>
    <string>$HEADLESS_BASE_DIR/logs/ollama_launchd.out.log</string>
    <key>StandardErrorPath</key>
    <string>$HEADLESS_BASE_DIR/logs/ollama_launchd.err.log</string>
    <key>WorkingDirectory</key>
    <string>/Users/$HEADLESS_SERVER_USER</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>/Users/$HEADLESS_SERVER_USER</string>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        <key>HEADLESS_SERVER_USER</key>
        <string>$HEADLESS_SERVER_USER</string>
        <key>HEADLESS_BASE_DIR</key>
        <string>$HEADLESS_BASE_DIR</string>
        <key>OLLAMA_HOST</key>
        <string>$OLLAMA_HOST</string>
        <key>OLLAMA_MODELS</key>
        <string>$OLLAMA_MODELS_DIR</string>
        <key>OLLAMA_KEEP_ALIVE</key>
        <string>$OLLAMA_KEEP_ALIVE</string>
        <key>OLLAMA_NUM_PARALLEL</key>
        <string>$OLLAMA_NUM_PARALLEL</string>
        <key>OLLAMA_MAX_LOADED_MODELS</key>
        <string>$OLLAMA_MAX_LOADED_MODELS</string>
    </dict>
    <key>ProcessType</key>
    <string>Background</string>
</dict>
</plist>"

TEMP_PLIST_PATH_OLLAMA="/tmp/$PLIST_FILENAME_OLLAMA"
echo "$PLIST_CONTENT_OLLAMA" > "$TEMP_PLIST_PATH_OLLAMA"
log_action "Temporary Ollama plist created at $TEMP_PLIST_PATH_OLLAMA"

# Unload and copy
if [ -f "$TARGET_PLIST_PATH_OLLAMA" ]; then
    log_action "Ollama Service $PLIST_LABEL_OLLAMA already exists. Unloading..."
    sudo launchctl unload "$TARGET_PLIST_PATH_OLLAMA" 2>/dev/null || true
fi
sudo cp "$TEMP_PLIST_PATH_OLLAMA" "$TARGET_PLIST_PATH_OLLAMA"
rm "$TEMP_PLIST_PATH_OLLAMA"
sudo chown root:wheel "$TARGET_PLIST_PATH_OLLAMA"
sudo chmod 644 "$TARGET_PLIST_PATH_OLLAMA"

# Load
log_action "Loading and starting service $PLIST_LABEL_OLLAMA..."
sudo launchctl load -w "$TARGET_PLIST_PATH_OLLAMA"
if [ $? -eq 0 ]; then
    log_action "Ollama Service $PLIST_LABEL_OLLAMA loaded. Check logs in $HEADLESS_BASE_DIR/logs and ~/.ollama/logs"
else
    log_action "ERROR: Failed to load Ollama service $PLIST_LABEL_OLLAMA."
    exit 1
fi

log_action "Optional Ollama service creation script finished."