#!/bin/bash
# =============================================================
# LANGKAH 1: BACKUP
# Jalankan ini PALING PERTAMA, sebelum langkah lain apapun.
# Ini HANYA membaca database (mongodump), tidak mengubah apapun,
# jadi 100% aman dijalankan di server yang sedang produksi.
#
# Cara pakai (di server, sebagai root/sudo):
#   chmod +x 1_backup.sh
#   ./1_backup.sh
# =============================================================
set -e

BACKUP_DIR="/root/genieacs-backup-$(date +%Y%m%d-%H%M%S)"

echo ">> Membuat folder backup: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Deteksi apakah GenieACS jalan native atau di dalam Docker container
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^genieacs-server$'; then
    echo ">> Terdeteksi mode Docker (container: genieacs-server)"
    MODE="docker"
else
    echo ">> Terdeteksi mode Native (mongod di host langsung)"
    MODE="native"
fi

if [ "$MODE" = "docker" ]; then
    docker exec genieacs-server mongodump --db genieacs \
        --collection config \
        --collection virtualParameters \
        --collection presets \
        --collection provisions \
        --out /tmp/genieacs-backup
    docker cp genieacs-server:/tmp/genieacs-backup "$BACKUP_DIR/dump"
    docker exec genieacs-server rm -rf /tmp/genieacs-backup
else
    mongodump --db genieacs \
        --collection config \
        --collection virtualParameters \
        --collection presets \
        --collection provisions \
        --out "$BACKUP_DIR/dump"
fi

echo ""
echo "=========================================================="
echo " BACKUP SELESAI: $BACKUP_DIR"
echo " Simpan folder ini baik-baik (copy ke luar server kalau bisa)."
echo ""
echo " Cara restore kalau ada yang salah nanti:"
if [ "$MODE" = "docker" ]; then
echo "   docker cp $BACKUP_DIR/dump genieacs-server:/tmp/restore"
echo "   docker exec genieacs-server mongorestore --db genieacs --drop /tmp/restore/genieacs"
else
echo "   mongorestore --db genieacs --drop $BACKUP_DIR/dump/genieacs"
fi
echo "=========================================================="
