#!/bin/bash
# =============================================================
# LANGKAH 2: CEK & PERBAIKI MONGODB YANG TER-EXPOSE
#
# Ini hanya mengubah cara mongod "mendengarkan" koneksi
# (dari semua interface -> localhost saja). Data TIDAK disentuh
# sama sekali, jadi aman untuk server yang sudah jalan.
# GenieACS app tetap bisa connect karena dia connect via
# "localhost:27017" (lihat genieacs.env), bukan via IP publik.
#
# Cara pakai (di server, sebagai root/sudo):
#   chmod +x 2_fix_mongo_exposure.sh
#   ./2_fix_mongo_exposure.sh
# =============================================================
set -e

if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^genieacs-server$'; then
    MODE="docker"
else
    MODE="native"
fi

echo ">> Mode terdeteksi: $MODE"
echo ""

check_exposed() {
    if [ "$MODE" = "docker" ]; then
        docker exec genieacs-server ss -tlnp 2>/dev/null | grep 27017 || true
    else
        ss -tlnp 2>/dev/null | grep 27017 || true
    fi
}

echo ">> Status listening MongoDB saat ini:"
RESULT=$(check_exposed)
echo "$RESULT"
echo ""

if echo "$RESULT" | grep -q "0.0.0.0:27017\|\*:27017"; then
    echo "!! TERKONFIRMASI: MongoDB listen di semua interface (TEREXPOSE)."
    echo ">> Memperbaiki sekarang..."

    if [ "$MODE" = "docker" ]; then
        # Shutdown mongod yang sedang bind ke semua interface
        docker exec genieacs-server mongod --shutdown --dbpath /data/db 2>/dev/null || \
            docker exec genieacs-server bash -c "mongosh --eval 'db.adminCommand({shutdown:1, force:true})'" 2>/dev/null || \
            docker exec genieacs-server bash -c "mongo --eval 'db.adminCommand({shutdown:1, force:true})'" 2>/dev/null || true

        sleep 3

        # Start ulang, kali ini bind ke localhost saja
        docker exec -d genieacs-server mongod --fork \
            --logpath /var/log/mongodb/mongod.log \
            --dbpath /data/db \
            --bind_ip 127.0.0.1

        sleep 3

        echo ""
        echo ">> PENTING: perbaikan ini berlaku sampai container di-restart."
        echo "   Supaya PERMANEN (bertahan walau container restart), update juga"
        echo "   entrypoint.sh di image Docker kamu dengan file yang saya lampirkan"
        echo "   (entrypoint.sh / entrypoint-simple.sh), lalu:"
        echo "     cd /opt/genieacs-docker"
        echo "     docker-compose build --no-cache"
        echo "     docker-compose up -d"
    else
        # Native: edit mongod.conf langsung, lalu restart service (aman, systemd)
        CONF="/etc/mongod.conf"
        if [ -f "$CONF" ]; then
            cp "$CONF" "$CONF.bak-$(date +%s)"
            sed -i 's/bindIp: .*/bindIp: 127.0.0.1/' "$CONF"
            systemctl restart mongod
            sleep 2
            echo ">> mongod.conf diupdate (backup config lama disimpan sebagai $CONF.bak-*)"
        else
            echo "!! $CONF tidak ditemukan, cek manual konfigurasi mongod kamu."
        fi
    fi

    echo ""
    echo ">> Verifikasi ulang..."
    sleep 2
    check_exposed
    echo ""
    echo ">> Tes koneksi GenieACS masih normal (restart service):"
    if [ "$MODE" = "docker" ]; then
        docker exec genieacs-server supervisorctl restart all
    else
        systemctl restart genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui
    fi
    sleep 3
    echo ">> Selesai. Cek UI GenieACS kamu (port 3000) masih bisa diakses normal."

else
    echo ">> AMAN: MongoDB tidak listen di 0.0.0.0. Tidak ada yang perlu diperbaiki."
fi

echo ""
echo ">> Langkah tambahan yang disarankan (opsional tapi bagus):"
echo "   ufw deny 27017/tcp    # blok port mongo dari luar di level firewall juga"
