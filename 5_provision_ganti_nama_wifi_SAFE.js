// ============================================================
// Provision: Universal ONU WiFi Auto-Rename (SAFE VERSION)
// Beda dari Provision_Auto_Ganti_Nama_Wifi.txt original:
//   - HANYA mengubah SSID (nama WiFi)
//   - TIDAK menyentuh BeaconType/security -> password WiFi
//     pelanggan yang sudah ada TETAP KEPAKAI, tidak jadi Open.
// Excludes: MikroTik (tidak ada config WiFi untuk MikroTik)
// ============================================================
// CATATAN: ini OPSIONAL, bukan bagian dari fix bug.
// Cuma dipakai kalau kamu memang mau fitur auto-rename SSID.
// Kalau tidak butuh, JANGAN paste ke provision manapun.
// ============================================================

const now = Date.now();
const daily = Date.now(86400000);

const brand = declare('DeviceID.Manufacturer', {value: daily}).value[0];

if (brand !== "MikroTik") {
  const productClass = declare("DeviceID.ProductClass", {value: now}).value[0];
  const serialNumber = declare("DeviceID.SerialNumber", {value: now}).value[0];

  const wlanConfig1 = declare("InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.SSID", {value: now});

  if (wlanConfig1.size && wlanConfig1.value && wlanConfig1.value[0]) {
    const currentSSID = wlanConfig1.value[0];

    if (currentSSID !== "ACS_AUTO") {
      log(">>> Rename SSID untuk: " + brand + " " + productClass + " (SN: " + serialNumber + ")");

      // HANYA ganti nama SSID. Security/password TIDAK disentuh sama sekali.
      declare("InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.SSID",
        {value: now}, {value: "ACS_AUTO"});

      // Enable WiFi (jaga-jaga kalau kepencet off), tidak mengubah keamanan
      declare("InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.Enable",
        {value: now}, {value: true});

      log(">>> SSID berhasil diganti jadi 'ACS_AUTO' (password TIDAK diubah)");
    }
  }
}
