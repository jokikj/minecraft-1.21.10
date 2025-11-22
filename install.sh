#!/bin/bash

# --- Core Paths and Variables Configuration ---
SERVER_ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
MINECRAFT_SERVER_DIR="${SERVER_ROOT_DIR}/server"
CONFIG_ENV_FILE="${SERVER_ROOT_DIR}/.env"

# --- MINECRAFT VERSION CONFIGURATION ---
# Le nom exact du fichier que tu veux
SERVER_JAR="minecraft_server.1.21.10.jar"

# URL officielle de Mojang pour la version 1.21.10
# (Vérifie toujours ce lien si une nouvelle version sort, mais celui-ci est pour la 1.21.10)
DOWNLOAD_URL="https://piston-data.mojang.com/v1/objects/95495a7f485eedd84ce928cef5e223b757d2f764/server.jar"

# Absolute paths
JAVA_BIN="/usr/bin/java"
SCREEN_BIN="/usr/bin/screen"
WGET_BIN="/usr/bin/wget"
RM_BIN="/usr/bin/rm"
CHOWN_BIN="/usr/bin/chown"
MKDIR_BIN="/usr/bin/mkdir"
UFW_BIN="/usr/sbin/ufw"
IPTABLES_BIN="/usr/sbin/iptables"
GREP_BIN="/usr/bin/grep"
SED_BIN="/usr/bin/sed"

# --- Load variables from the .env file ---
if [ -f "$CONFIG_ENV_FILE" ]; then
    set -a
    . "$CONFIG_ENV_FILE"
    set +a
else
    echo "ERROR Install: Minecraft configuration file '$CONFIG_ENV_FILE' not found!"
    exit 1
fi

# Define user if not set
if [ -z "$MINECRAFT_USER" ]; then
    MINECRAFT_USER="$(whoami)"
fi

# Check requirements
if [ -z "$RAM" ] || [ -z "$PORT" ]; then
    echo "ERROR Install: RAM or PORT variables missing in .env!"
    exit 1
fi

echo "--- Minecraft Server Installation ---"
echo "Target Version: 1.21.10"
echo "User: $MINECRAFT_USER | Port: $PORT | RAM: $RAM"

# --- System Updates & Java ---
echo "Updating system and installing Java 21..."
sudo apt update -y && sudo apt upgrade -y
sudo apt-get install openjdk-21-jre-headless screen -y

# --- Firewall ---
echo "Opening port $PORT..."
sudo "$UFW_BIN" allow "$PORT"
sudo "$IPTABLES_BIN" -I INPUT -p tcp --dport "$PORT" -j ACCEPT

# --- Directory Setup ---
echo "Creating directory structure..."
sudo "$MKDIR_BIN" -p "$MINECRAFT_SERVER_DIR"
sudo "$CHOWN_BIN" "$MINECRAFT_USER:$MINECRAFT_USER" "$MINECRAFT_SERVER_DIR"

# --- Download & Install ---
echo "Downloading Minecraft server 1.21.10..."
sudo -u "$MINECRAFT_USER" bash << EOF_MINECRAFT_SETUP
cd "$MINECRAFT_SERVER_DIR" || exit 1

# Remove specifically the target jar if it exists to ensure fresh download
"$RM_BIN" -f "$SERVER_JAR"

# Download the specific version
"$WGET_BIN" -O "$SERVER_JAR" "$DOWNLOAD_URL"

# Accept EULA
echo "eula=true" > eula.txt
EOF_MINECRAFT_SETUP

# --- Verification ---
if [ ! -f "${MINECRAFT_SERVER_DIR}/${SERVER_JAR}" ]; then
    echo "ERROR Install: Failed to download $SERVER_JAR."
    exit 1
fi
echo "Download successful: $SERVER_JAR"

# --- Server Properties ---
SERVER_PROPERTIES_PATH="${MINECRAFT_SERVER_DIR}/server.properties"
echo "Configuring server.properties..."

sudo -u "$MINECRAFT_USER" bash << EOF_PROPERTIES_CONFIG
cd "$MINECRAFT_SERVER_DIR" || exit 1

# Create basic properties if missing
if [ ! -f "$SERVER_PROPERTIES_PATH" ]; then
    echo "enable-query=false" > "$SERVER_PROPERTIES_PATH"
    echo "server-port=$PORT" >> "$SERVER_PROPERTIES_PATH"
    echo "motd=Minecraft Server 1.21.10" >> "$SERVER_PROPERTIES_PATH"
else
    # Update existing port
    if "$GREP_BIN" -q "^server-port=" "$SERVER_PROPERTIES_PATH"; then
        "$SED_BIN" -i "s/^server-port=.*/server-port=${PORT}/" "$SERVER_PROPERTIES_PATH"
    else
        echo "server-port=${PORT}" >> "$SERVER_PROPERTIES_PATH"
    fi
fi
EOF_PROPERTIES_CONFIG

echo ""
echo -e "\033[1;32mInstallation Completed for Minecraft 1.21.10!\033[0m"
echo "You can now run ./start.sh"
exit 0
