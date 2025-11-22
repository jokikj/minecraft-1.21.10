#!/bin/bash

# --- Détection du chemin du script ---
SERVER_ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo -e "\033[0;36mWorking from $SERVER_ROOT_DIR\033[0m" # Cyan color

# --- Config screen ---
SCREEN_BIN="/usr/bin/screen"
GREP_BIN="/usr/bin/grep"
SLEEP_BIN="/usr/bin/sleep"

SCREEN_SESSION_NAME="mc"

echo "" # Add a blank line for better separation
echo -e "\033[1;34m-------------------------------------------------\033[0m" 
echo -e "\033[1;34m Minecraft Server Stop \033[0m" # Blue color, bold
echo -e "\033[1;34m-------------------------------------------------\033[0m" 
echo -e "\033[0;33mAttempting to stop Minecraft server...\033[0m" # Yellow color

# Vérifier si la session screen existe
if "$SCREEN_BIN" -list | "$GREP_BIN" -q "$SCREEN_SESSION_NAME"; then
    echo -e "\033[0;32mScreen session '$SCREEN_SESSION_NAME' found. Sending '/stop' command...\033[0m" # Green color

    # Envoyer la commande /stop (avec un retour chariot)
    "$SCREEN_BIN" -S "$SCREEN_SESSION_NAME" -X stuff "/stop$(printf \\r)"

    echo -e "\033[0;33mStop command sent. Waiting for server to shut down...\033[0m" # Yellow color

    # Attendre que la session screen disparaisse (boucle d'attente)
    for i in {1..30}; do
        if ! "$SCREEN_BIN" -list | "$GREP_BIN" -q "$SCREEN_SESSION_NAME"; then
            echo -e "\033[1;32mMinecraft server stopped cleanly.\033[0m" # Green color, bold
            echo -e "\033[1;34m-------------------------------------------------\033[0m" # Blue line
            echo ""
            exit 0
        fi
        "$SLEEP_BIN" 1
    done

    echo -e "\033[1;31mWARNING: Server did not stop within expected time. You may need to check manually.\033[0m" # Red color, bold
else
    echo -e "\033[0;31mMinecraft server is not running (screen session '$SCREEN_SESSION_NAME' not found).\033[0m" # Red color
fi

echo -e "\033[1;34m-------------------------------------------------\033[0m" # Blue line
echo ""
