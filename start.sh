#!/bin/bash

# --- Core Paths ---
SERVER_ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
MINECRAFT_SERVER_DIR="${SERVER_ROOT_DIR}/server"
CONFIG_ENV_FILE="${SERVER_ROOT_DIR}/.env"

# --- VERSION ---
# Doit correspondre au fichier téléchargé par install.sh
SERVER_JAR="minecraft_server.1.21.10.jar"

# Paths to binaries
JAVA_BIN="/usr/bin/java"
SCREEN_BIN="/usr/bin/screen"
GREP_BIN="/usr/bin/grep"
CUT_BIN="/usr/bin/cut"
SED_BIN="/usr/bin/sed"
PS_BIN="/usr/bin/ps"
KILL_BIN="/usr/bin/kill"
SLEEP_BIN="/usr/bin/sleep"
TR_BIN="/usr/bin/tr"
HOSTNAME_BIN="/usr/bin/hostname"
CURL_BIN="/usr/bin/curl"

# --- Load Config ---
if [ -f "$CONFIG_ENV_FILE" ]; then
    set -a
    . "$CONFIG_ENV_FILE"
    set +a
else
    echo "ERROR: .env file missing."
    exit 1
fi

if [ -z "$MINECRAFT_USER" ]; then MINECRAFT_USER="$(whoami)"; fi

echo "--- Start Minecraft 1.21.10 ---"
echo "User: $MINECRAFT_USER | Port: $PORT | RAM: $RAM"

# --- Pre-flight Checks ---
if [ ! -f "${MINECRAFT_SERVER_DIR}/${SERVER_JAR}" ]; then
    echo "ERROR: ${SERVER_JAR} not found in $MINECRAFT_SERVER_DIR."
    echo "Please run install.sh first."
    exit 1
fi

SCREEN_SESSION_NAME="mc"

# Check if already running
if sudo -u "$MINECRAFT_USER" "$SCREEN_BIN" -ls | "$GREP_BIN" -q "\.${SCREEN_SESSION_NAME}"; then
    echo "Screen session '$SCREEN_SESSION_NAME' is already active."
    echo "Attach with: screen -r $SCREEN_SESSION_NAME"
    exit 1
fi

# Clean up stuck processes
PIDS=$(sudo -u "$MINECRAFT_USER" "$PS_BIN" -eo pid,user,cmd | "$GREP_BIN" "$MINECRAFT_SERVER_DIR" | "$GREP_BIN" "java" | "$GREP_BIN" -v "grep" | "$TR_BIN" -s ' ' | "$CUT_BIN" -d' ' -f1)
if [ -n "$PIDS" ]; then
    echo "Cleaning up old Java processes..."
    sudo "$KILL_BIN" $PIDS 2>/dev/null || true
    "$SLEEP_BIN" 2
fi

# Ensure port is correct in properties before launch
SERVER_PROPERTIES_PATH="${MINECRAFT_SERVER_DIR}/server.properties"
if [ -f "$SERVER_PROPERTIES_PATH" ]; then
    CUR_PORT=$(sudo -u "$MINECRAFT_USER" "$GREP_BIN" "^server-port=" "$SERVER_PROPERTIES_PATH" | "$CUT_BIN" -d'=' -f2)
    if [[ "$CUR_PORT" != "$PORT" ]]; then
        echo "Updating port in server.properties..."
        sudo -u "$MINECRAFT_USER" "$SED_BIN" -i "s/^server-port=.*/server-port=${PORT}/" "$SERVER_PROPERTIES_PATH"
    fi
fi

# --- Launch Server ---
echo "Launching $SERVER_JAR..."
sudo -u "$MINECRAFT_USER" bash << EOF_START
cd "$MINECRAFT_SERVER_DIR" || exit 1
# Launch command matching your screenshot requirements
"$SCREEN_BIN" -dmS "$SCREEN_SESSION_NAME" "$JAVA_BIN" -Xmx${RAM} -Xms${RAM} -jar "$SERVER_JAR" nogui
EOF_START

if [ $? -eq 0 ]; then
    echo -e "\033[1;32mServer started successfully in screen '$SCREEN_SESSION_NAME'.\033[0m"
    echo "Command to access console: screen -r $SCREEN_SESSION_NAME"
    exit 0
else
    echo "ERROR: Failed to start screen session."
    exit 1
fi
