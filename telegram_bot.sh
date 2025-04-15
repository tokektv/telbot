#!/bin/sh

# Konfigurasi Bot
BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"
LOG_FILE="/tmp/telegram_bot.log"
LAST_LOG_FILE="/tmp/last_openwrt_log"

# Identifikasi Router (ubah ini untuk setiap router)
ROUTER_ID="Router-01"  # Ganti dengan ID unik untuk setiap router
ROUTER_LOCATION="Kantor Pusat"  # Deskripsi lokasi opsional

# Fungsi untuk mengirim pesan ke Telegram
send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="*${ROUTER_ID}* (${ROUTER_LOCATION})%0A%0A${message}" \
        -d parse_mode="Markdown" >> ${LOG_FILE}
}

# Fungsi untuk memeriksa log login
check_login_activity() {
    local current_log=$(logread | grep -E "dropbear|password|login|user")
    local last_log=$(cat ${LAST_LOG_FILE} 2>/dev/null)
    
    if [ "$current_log" != "$last_log" ]; then
        local new_entries=$(printf "%s\n%s" "$last_log" "$current_log" | sort | uniq -u)
        
        if [ -n "$new_entries" ]; then
            send_telegram_message "🔐 *Log Aktivitas Login* 🔐%0A%0A${new_entries}"
            echo "$current_log" > ${LAST_LOG_FILE}
        fi
    fi
}

# Fungsi untuk memeriksa perubahan konfigurasi
check_config_changes() {
    local current_config=$(uci changes)
    
    if [ -n "$current_config" ]; then
        send_telegram_message "⚙️ *Perubahan Konfigurasi* ⚙️%0A%0A${current_config}"
        uci commit
    fi
}

# Main loop
while true; do
    check_login_activity
    check_config_changes
    sleep 10
done
