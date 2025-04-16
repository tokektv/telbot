#Cara menambahkan router
./setup_router.sh "Router-02" "Cabang Bandung"

opkg update
opkg install curl coreutils-md5sum jq

chmod +x /root/telegram_bot.sh
chmod +x /etc/init.d/telegram_bot
/etc/init.d/telegram_bot enable
/etc/init.d/telegram_bot start
