# Paket Perbaikan GenieACS

Semua script di sini AMAN dijalankan di server yang sedang produksi
(sedang dipakai banyak pelanggan). Tidak ada yang menghapus data
pelanggan atau device yang sudah terdaftar.

## Cara pakai

1. Upload seluruh folder ini ke server GenieACS kamu, misal ke `/root/fixpack/`.
2. Masuk sebagai root/sudo.
3. Jalankan **BERURUTAN**, satu per satu, jangan diloncat:

```bash
cd /root/fixpack
chmod +x *.sh

# LANGKAH 1 - WAJIB PALING PERTAMA
./1_backup.sh

# LANGKAH 2 - perbaiki MongoDB yang ter-expose ke publik
./2_fix_mongo_exposure.sh

# LANGKAH 3/4 - perbaiki virtual parameter pppoeUsername & pppoeMac
./4_apply_virtual_parameters.sh

# LANGKAH 5 - cek kredensial default (read-only, cuma kasih peringatan)
./6_check_default_credentials.sh
```

4. File `5_provision_ganti_nama_wifi_SAFE.js` itu **OPSIONAL** — cuma
   dipakai kalau kamu memang mau fitur auto-rename SSID. Kalau mau
   pakai: buka isinya, copy semua, paste ke GenieACS UI -> Admin ->
   Provisions -> buat provision baru (atau tempel ke provision
   `inform` yang sudah ada, di bagian bawah script yang sudah ada).
   Kalau tidak butuh fitur ini, **abaikan file ini, tidak usah dipakai**.

## Apa yang TIDAK dilakukan otomatis (perlu kamu putuskan sendiri)

- **Ganti kredensial default `msn/msn`** — script `6_check_default_credentials.sh`
  cuma mendeteksi dan kasih peringatan, tidak auto-ganti, karena ini
  butuh kamu tentukan sendiri username/password barunya.
- **Docker network_mode: host -> bridge** — ini perubahan besar yang
  bisa mempengaruhi ZeroTier kalau kamu memang pakai ZeroTier untuk
  jangkau ONU. Tidak saya otomatisasi karena risikonya tergantung
  setup kamu. Kalau kamu TIDAK pakai ZeroTier sama sekali, bisa
  pertimbangkan pindah ke `docker-compose-simple.yml` yang sudah ada
  di paket installer asli kamu.
- **Upgrade MongoDB dari versi 4.4 (EOL)** — ini perubahan besar,
  butuh rencana migrasi terpisah, tidak aman dilakukan sebagai
  "quick fix".

## Urutan file di folder ini

| File | Fungsi | Wajib/Opsional |
|---|---|---|
| `1_backup.sh` | Backup 4 collection penting sebelum apa-apa | Wajib, jalankan pertama |
| `2_fix_mongo_exposure.sh` | Cek & tutup akses MongoDB dari publik | Wajib |
| `3a_pppoeUsername.js` | Source code perbaikan (dipakai oleh langkah 4) | - |
| `3b_pppoeMac.js` | Source code perbaikan (dipakai oleh langkah 4) | - |
| `vp_pppoeUsername.json` | Data siap-import (dipakai oleh langkah 4) | - |
| `vp_pppoeMac.json` | Data siap-import (dipakai oleh langkah 4) | - |
| `4_apply_virtual_parameters.sh` | Apply perbaikan pppoeUsername & pppoeMac ke DB | Wajib |
| `5_provision_ganti_nama_wifi_SAFE.js` | Auto-rename SSID tanpa hapus password | Opsional |
| `6_check_default_credentials.sh` | Cek kredensial default msn/msn | Disarankan |
| `entrypoint.sh` / `entrypoint-simple.sh` | Versi patch untuk rebuild image Docker (permanen) | Untuk Docker saja |
