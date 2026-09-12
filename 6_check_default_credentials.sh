#!/bin/bash
# =============================================================
# LANGKAH 6: CEK KREDENSIAL DEFAULT (read-only, tidak mengubah apapun)
#
# Ini cuma membaca isi provision "inform" dan kasih tahu kalau
# masih ada kredensial default "msn/msn" yang belum diganti.
# TIDAK melakukan perubahan apapun ke server.
#
# Cara pakai:
#   chmod +x 6_check_default_credentials.sh
#   ./6_check_default_credentials.sh
# =============================================================

if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^genieacs-server$'; then
    SCRIPT_CONTENT=$(docker exec genieacs-server mongosh genieacs --quiet --eval \
        'db.provisions.findOne({_id:"inform"}).script' 2>/dev/null || \
        docker exec genieacs-server mongo genieacs --quiet --eval \
        'db.provisions.findOne({_id:"inform"}).script' 2>/dev/null)
else
    SCRIPT_CONTENT=$(mongosh genieacs --quiet --eval \
        'db.provisions.findOne({_id:"inform"}).script' 2>/dev/null || \
        mongo genieacs --quiet --eval \
        'db.provisions.findOne({_id:"inform"}).script' 2>/dev/null)
fi

echo "=========================================================="
if echo "$SCRIPT_CONTENT" | grep -q '"msn"'; then
    echo "!! PERINGATAN: Provision 'inform' kamu masih pakai kredensial"
    echo "   default 'msn' / 'msn' untuk ManagementServer / Connection"
    echo "   Request. Ini dipakai semua orang yang pernah pakai paket"
    echo "   installer yang sama -> SEBAIKNYA DIGANTI."
    echo ""
    echo "   Cara ganti: GenieACS UI -> Admin -> Provisions -> 'inform'"
    echo "   -> ubah baris:"
    echo "        const AcsUser = \"msn\";"
    echo "        const AcsPass = \"msn\";"
    echo "        let ConnReqUser = \"msn\";"
    echo "        const ConnReqPass = \"msn\";"
    echo "   ganti ke value unik punya kamu sendiri, lalu Save."
    echo ""
    echo "   PENTING: setelah ganti connReq user/pass, device yang"
    echo "   SUDAH terdaftar akan otomatis ter-update kredensialnya"
    echo "   di inform berikutnya -> tidak perlu setting manual per device."
else
    echo ">> AMAN: tidak terdeteksi kredensial default 'msn' di provision 'inform'."
fi
echo "=========================================================="
