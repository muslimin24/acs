// Mac Address PPPoE Pada devices berbeda (FIXED v2)
// v2: beberapa vendor (contoh: FiberHome HG6145D2) menyimpan MAC di
// WANIPConnection.X.MACAddress, bukan di WANPPPConnection.X.MACAddress.
// Sekarang dua-duanya dicek, dengan urutan prioritas: PPPConnection dulu
// (karena itu MAC session PPPoE yang sebenarnya), baru fallback ke
// IPConnection kalau tidak ketemu, lalu fallback wildcard penuh di akhir.

let m = "";

const keys = [
  // --- WANPPPConnection (mayoritas vendor: ZTE, Huawei, dll) ---
  "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANPPPConnection.1.MACAddress",
  "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANPPPConnection.2.MACAddress",
  "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.2.WANPPPConnection.1.MACAddress",
  "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.2.WANPPPConnection.2.MACAddress",
  "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.3.WANPPPConnection.1.MACAddress",
  "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.4.WANPPPConnection.1.MACAddress",
  "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.5.WANPPPConnection.1.MACAddress",

  // --- WANIPConnection (contoh: FiberHome HG6145D2) ---
  "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANIPConnection.1.MACAddress",
  "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANIPConnection.2.MACAddress",
  "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.2.WANIPConnection.1.MACAddress",
  "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.2.WANIPConnection.2.MACAddress",
  "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.3.WANIPConnection.1.MACAddress",
  "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.4.WANIPConnection.1.MACAddress",
  "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.5.WANIPConnection.1.MACAddress",

  // --- fallback: sapu semua kombinasi PPP & IP yang mungkin lolos di atas ---
  "InternetGatewayDevice.WANDevice.*.WANConnectionDevice.*.WANPPPConnection.*.MACAddress",
  "InternetGatewayDevice.WANDevice.*.WANConnectionDevice.*.WANIPConnection.*.MACAddress"
];

for (let key of keys) {
  let d = declare(key, {value: Date.now()});
  if (d.size) {
    for (let p of d) {
      if (p.value && p.value[0]) {
        m = p.value[0];
        break;
      }
    }
  }
  if (m) break;
}

return {writable: false, value: [m, "xsd:string"]};
