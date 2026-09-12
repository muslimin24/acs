#!/bin/bash
# =============================================================
# LANGKAH 8: PERBAIKI KOLOM "Mac" & "ID" DI HALAMAN LIST DEVICE
#
# Masalah: kolom "Mac" di halaman list (bukan halaman detail
# device) baca langsung dari path mentah yang di-hardcode ke
# WANConnectionDevice.1.WANPPPConnection.1 - tidak lewat virtual
# parameter pppoeMac yang sudah kita perbaiki. Kolom "ID" juga
# baca dari pppoeUsername2 (virtual parameter LAIN, bukan
# pppoeUsername yang sudah kita perbaiki).
#
# Fix ini HANYA mengubah 2 baris config (ui.index.13.parameter
# dan ui.index.4.parameter) supaya keduanya ikut memakai virtual
# parameter pppoeMac / pppoeUsername yang sudah benar. Tidak ada
# collection lain yang disentuh, tidak ada device yang terpengaruh
# datanya sama sekali - ini murni ubah "kolom ini nampilin data
# dari mana" di tampilan UI.
#
# Cara pakai (di server, dari folder fixpack):
#   chmod +x 8_fix_index_columns.sh
#   ./8_fix_index_columns.sh
# =============================================================
set -e

if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^genieacs-server$'; then
    MODE="docker"
else
    MODE="native"
fi

echo ">> Mode terdeteksi: $MODE"

apply_one() {
    local file="$1"

    if [ "$MODE" = "docker" ]; then
        docker cp "$file" genieacs-server:/tmp/"$file"
        docker exec genieacs-server mongoimport --db genieacs --collection config \
            --mode=upsert --upsertFields=_id --file=/tmp/"$file"
        docker exec genieacs-server rm -f /tmp/"$file"
    else
        mongoimport --db genieacs --collection config \
            --mode=upsert --upsertFields=_id --file="$file"
    fi
    echo ">> $file diterapkan."
}

apply_one "cfg_ui_index_13_parameter.json"   # kolom "Mac" -> VirtualParameters.pppoeMac
apply_one "cfg_ui_index_4_parameter.json"    # kolom "ID"  -> VirtualParameters.pppoeUsername

echo ""
echo "=========================================================="
echo " SELESAI. Reload halaman GenieACS UI di browser kamu"
echo " (Ctrl+F5 / hard refresh) untuk lihat perubahannya."
echo " Data yang tampil akan ikut nilai VirtualParameters yang"
echo " sudah ada saat ini di tiap device - tidak perlu summon"
echo " ulang semua device."
echo "=========================================================="
