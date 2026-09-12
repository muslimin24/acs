// PPPoE Username (FIXED)
// Perbaikan: sebelumnya v1.value[0] diambil langsung dari hasil declare()
// yang di-wildcard di WANConnectionDevice.* -- kalau ada lebih dari satu
// WANConnectionDevice yang match, .value[0] bisa mengambil entry yang
// salah/kosong. Sekarang setiap kandidat di-loop item per item (for...of)
// dan kombinasi index diperluas + ditambah fallback wildcard penuh supaya
// tidak ada device yang lolos tidak terbaca.

let user = "";

if (args[1].value) {
  // Mode SET (user mengubah value dari UI) - tetap seperti semula
  user = args[1].value[0];
  declare("InternetGatewayDevice.WANDevice.*.WANConnectionDevice.*.WANPPPConnection.*.Username", null, {value: user});
} else {
  // Mode GET - baca dengan urutan prioritas, loop tiap hasil match
  const keys = [
    // kombinasi umum: WANConnectionDevice 1-5, WANPPPConnection 1-5
    "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANPPPConnection.1.Username",
    "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANPPPConnection.2.Username",
    "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.2.WANPPPConnection.1.Username",
    "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.2.WANPPPConnection.2.Username",
    "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.3.WANPPPConnection.1.Username",
    "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.3.WANPPPConnection.2.Username",
    "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.4.WANPPPConnection.1.Username",
    "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.4.WANPPPConnection.2.Username",
    "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.5.WANPPPConnection.1.Username",
    "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.5.WANPPPConnection.2.Username",
    // fallback: sapu semua kombinasi yang mungkin lolos dari daftar di atas
    "InternetGatewayDevice.WANDevice.*.WANConnectionDevice.*.WANPPPConnection.*.Username"
  ];

  user = getParameterValue(keys);
}

return {writable: true, value: [user, "xsd:string"]};

function getParameterValue(keys) {
  for (let key of keys) {
    // lewati koneksi yang mode-nya PPPoE_Bridged (bukan PPPoE aktif)
    if (key.includes("Username")) {
      let connectionTypeKey = key.replace("Username", "ConnectionType");
      let connectionType = declare(connectionTypeKey, {value: Date.now()});
      if (connectionType.size && connectionType.value[0] === "PPPoE_Bridged") {
        continue;
      }
    }

    let d = declare(key, {path: Date.now() - (120 * 1000), value: Date.now()});

    for (let item of d) {
      if (item.value && item.value[0] && item.value[0] !== "") {
        return item.value[0];
      }
    }
  }

  return "";
}
