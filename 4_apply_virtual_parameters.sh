#!/bin/bash
# =============================================================
# LANGKAH 4: APPLY PERBAIKAN pppoeUsername & pppoeMac
#
# Ini melakukan UPSERT (update-if-exists) pada 2 dokumen saja
# di collection virtualParameters, berdasarkan _id yang sama
# persis ("pppoeUsername" dan "pppoeMac"). Dokumen/virtual
# parameter LAIN (pppoeIP, gettemp, dst) TIDAK disentuh sama
# sekali. Ini setara dengan kamu buka UI -> edit script -> Save,
# cuma dilakukan otomatis lewat command.
#
# Pastikan file-file ini ada di folder yang sama:
#   vp_pppoeUsername.json
#   vp_pppoeMac.json
#
# Cara pakai (di server, sebagai root/sudo, dari folder fixpack ini):
#   chmod +x 4_apply_virtual_parameters.sh
#   ./4_apply_virtual_parameters.sh
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
    local id="$2"

    if [ "$MODE" = "docker" ]; then
        docker cp "$file" genieacs-server:/tmp/"$file"
        docker exec genieacs-server mongoimport --db genieacs --collection virtualParameters \
            --mode=upsert --upsertFields=_id --file=/tmp/"$file"
        docker exec genieacs-server rm -f /tmp/"$file"
    else
        mongoimport --db genieacs --collection virtualParameters \
            --mode=upsert --upsertFields=_id --file="$file"
    fi
    echo ">> Virtual parameter '$id' berhasil diupdate."
}

apply_one "vp_pppoeUsername.json" "pppoeUsername"
apply_one "vp_pppoeMac.json" "pppoeMac"

echo ""
echo "=========================================================="
echo " SELESAI."
echo " Perubahan otomatis berlaku untuk device yang inform/summon"
echo " berikutnya. Tidak perlu restart genieacs-cwmp/nbi/ui,"
echo " tapi kalau mau langsung lihat hasilnya sekarang, summon"
echo " manual salah satu device dari GenieACS UI."
echo "=========================================================="
