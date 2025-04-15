#!/bin/sh

# Konfigurasi Bot
BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"
LOG_FILE="/tmp/telegram_bot.log"

# Sistem penyimpanan state terakhir
LAST_LOGIN_HASH="/tmp/last_login_hash"
LAST_CONFIG_HASH="/tmp/last_config_hash"

# Identifikasi Router
ROUTER_ID="Router-01"
ROUTER_LOCATION="Kantor Pusat"

# Fungsi untuk menghasilkan hash dari konten
generate_hash() {
    echo "$1" | md5sum | cut -d' ' -f1
}

# Fungsi untuk mengirim pesan ke Telegram
send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="*${ROUTER_ID}* (${ROUTER_LOCATION})%0A%0A${message}" \
        -d parse_mode="Markdown" >> ${LOG_FILE}
}

# Fungsi untuk memeriksa log login dengan hash comparison
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

# Fungsi untuk memeriksa perubahan konfigurasi dengan hash comparison
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

# Main loop
while true; do
    check_login_activity
    check_config_changes
    sleep 15  # Interval diperpanjang untuk mengurangi duplikasi
done
