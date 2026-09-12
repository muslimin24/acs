// =============================================================
// DIAGNOSA v2: cari device yang pppoeUsername/pppoeMac masih blank,
// dikelompokkan per Manufacturer + ProductClass.
// FIX: pakai _deviceId._Manufacturer / _deviceId._ProductClass
// (skema asli GenieACS), bukan DeviceID.Manufacturer.
// Ini QUERY READ-ONLY, tidak mengubah data apapun.
//
// Cara pakai (di server):
//   mongo genieacs --quiet 7_diagnose_blank_v2.js
// =============================================================

function fieldVal(doc, path) {
  const parts = path.split(".");
  let cur = doc;
  for (const p of parts) {
    if (!cur) return undefined;
    cur = cur[p];
  }
  if (cur && typeof cur === "object" && "_value" in cur) return cur._value;
  return cur;
}

const devices = db.devices.find({}, {
  "_deviceId": 1,
  "VirtualParameters.pppoeUsername": 1,
  "VirtualParameters.pppoeMac": 1,
  "_id": 1
}).toArray();

const groups = {};

for (const d of devices) {
  const mfr = (d._deviceId && d._deviceId._Manufacturer) || "(unknown)";
  const model = (d._deviceId && d._deviceId._ProductClass) || "(unknown)";
  const user = fieldVal(d, "VirtualParameters.pppoeUsername");
  const mac = fieldVal(d, "VirtualParameters.pppoeMac");

  const userBlank = !user || user === "";
  const macBlank = !mac || mac === "";

  if (!userBlank && !macBlank) continue;

  let status = [];
  if (userBlank) status.push("username-blank");
  if (macBlank) status.push("mac-blank");
  const key = mfr + " | " + model + " | " + status.join("+");

  if (!groups[key]) groups[key] = { count: 0, samples: [] };
  groups[key].count++;
  if (groups[key].samples.length < 5) groups[key].samples.push(d._id);
}

const sorted = Object.entries(groups).sort((a, b) => b[1].count - a[1].count);

print("==============================================================");
print("REKAP DEVICE DENGAN pppoeUsername/pppoeMac MASIH BLANK");
print("(diurutkan dari yang paling banyak)");
print("==============================================================");
for (const [key, info] of sorted) {
  print(info.count + "x  ->  " + key);
  print("      contoh device id: " + info.samples.join(", "));
}
print("==============================================================");
print("Total kelompok bermasalah: " + sorted.length);
print("Total device bermasalah  : " + sorted.reduce((a, [, v]) => a + v.count, 0));
