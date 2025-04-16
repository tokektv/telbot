#!/bin/sh

# Konfigurasi Bot
BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"
LOG_FILE="/tmp/telegram_bot.log"
API_URL="https://api.telegram.org/bot${BOT_TOKEN}"

# Sistem penyimpanan state
LAST_UPDATE_ID_FILE="/tmp/last_update_id"
LAST_LOGIN_HASH="/tmp/last_login_hash"
LAST_CONFIG_HASH="/tmp/last_config_hash"

# Identifikasi Router
ROUTER_ID="Router-01"
ROUTER_LOCATION="Kantor Pusat"

# Fungsi utilitas
generate_hash() {
    echo "$1" | md5sum | cut -d' ' -f1
}

send_telegram_message() {
    local message="$1"
    curl -s -X POST "${API_URL}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="*${ROUTER_ID}* (${ROUTER_LOCATION})%0A%0A${message}" \
        -d parse_mode="Markdown" >> ${LOG_FILE}
}

get_router_status() {
    local uptime=$(uptime | awk -F'( |,|:)+' '{print $6" jam, "$7" menit"}')
    local memory=$(free -m | awk 'NR==2{printf "%.2f%% (%sMB/%sMB)", $3*100/$2, $3, $2}')
    local disk=$(df -h / | awk 'NR==2{print $5}')
    local load=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')
    
    echo "🔄 *Status Router* 🔄
⏳ Uptime: ${uptime}
🧠 Memory: ${memory}
💾 Disk: ${disk} terpakai
📊 Load Average: ${load}
🌐 IP Public: $(curl -s ifconfig.me)"
}

# Fungsi monitoring
check_login_activity() {
    local current_log=$(logread | grep -E "dropbear|password|login|user" | tail -n 5)
    local current_hash=$(generate_hash "$current_log")
    local last_hash=$(cat ${LAST_LOGIN_HASH} 2>/dev/null)
    
    if [ "$current_hash" != "$last_hash" ]; then
        if [ -n "$current_log" ]; then
            send_telegram_message "🔐 *Log Aktivitas Login* 🔐%0A%0A${current_log}"
            echo "$current_hash" > ${LAST_LOGIN_HASH}
        fi
    fi
}

check_config_changes() {
    local current_config=$(uci changes)
    local current_hash=$(generate_hash "$current_config")
    local last_hash=$(cat ${LAST_CONFIG_HASH} 2>/dev/null)
    
    if [ "$current_hash" != "$last_hash" ]; then
        if [ -n "$current_config" ]; then
            send_telegram_message "⚙️ *Perubahan Konfigurasi* ⚙️%0A%0A${current_config}"
            uci commit
            echo "$current_hash" > ${LAST_CONFIG_HASH}
        fi
    fi
}

# Fungsi handle command
handle_commands() {
    local update_id=$1
    local message_text=$2
    
    case $message_text in
        /status*)
            send_telegram_message "$(get_router_status)"
            ;;
        /restart*)
            send_telegram_message "⚠️ Router akan di-restart..."
            reboot
            ;;
        /help*)
            send_telegram_message "📚 *Daftar Perintah* 📚
/status - Cek status router
/restart - Restart router
/logs - Tampilkan log terakhir
/help - Tampilkan bantuan ini"
            ;;
        /logs*)
            send_telegram_message "📜 *Log Terakhir* 📜%0A%0A$(logread | tail -n 15)"
            ;;
        *)
            # Unknown command
            ;;
    esac
    
    echo $update_id > ${LAST_UPDATE_ID_FILE}
}

check_telegram_commands() {
    local last_update_id=$(cat ${LAST_UPDATE_ID_FILE} 2>/dev/null || echo 0)
    local updates=$(curl -s "${API_URL}/getUpdates?offset=$((last_update_id + 1))")
    
    echo $updates | jq -r '.result[] | [.update_id, .message.text // "", .message.chat.id] | @tsv' | \
    while IFS=$'\t' read -r update_id message_text chat_id; do
        if [ "$chat_id" = "$CHAT_ID" ]; then
            handle_commands "$update_id" "$message_text"
        fi
    done
}

# Main loop
while true; do
    check_login_activity
    check_config_changes
    check_telegram_commands
    sleep 10
done
