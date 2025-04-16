#!/bin/sh

# Script setup_router.sh - Jalankan di setiap router

# Konfigurasi dasar
ROUTER_ID=$1
ROUTER_LOCATION=$2
BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"

# Download script dari server pusat (opsional)
curl -o /root/telegram_bot.sh "http://your-server/telegram_bot_template.sh"

# Ganti placeholder dengan nilai aktual
sed -i "s/ROUTER_ID=\".*\"/ROUTER_ID=\"${ROUTER_ID}\"/" /root/telegram_bot.sh
sed -i "s/ROUTER_LOCATION=\".*\"/ROUTER_LOCATION=\"${ROUTER_LOCATION}\"/" /root/telegram_bot.sh
sed -i "s/BOT_TOKEN=\".*\"/BOT_TOKEN=\"${BOT_TOKEN}\"/" /root/telegram_bot.sh
sed -i "s/CHAT_ID=\".*\"/CHAT_ID=\"${CHAT_ID}\"/" /root/telegram_bot.sh

# Set permissions
chmod +x /root/telegram_bot.sh

# Buat service
cat > /etc/init.d/telegram_bot <<EOF
#!/bin/sh /etc/rc.common

START=99
STOP=10

start() {
    /root/telegram_bot.sh >/dev/null 2>&1 &
}

stop() {
    killall telegram_bot.sh
}
EOF

chmod +x /etc/init.d/telegram_bot
/etc/init.d/telegram_bot enable
/etc/init.d/telegram_bot start
