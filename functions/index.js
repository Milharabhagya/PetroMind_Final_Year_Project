const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();
const db = admin.firestore();

const CURRENT_PRICES = {
  retail: [
    { id: "petrol_92", name: "Petrol 92 Octane", price: 292.0, category: "retail", effectiveDate: "Effective Midnight, Jan 31/Feb 1, 2026" },
    { id: "petrol_95", name: "Petrol 95 Octane", price: 340.0, category: "retail", effectiveDate: "Effective Midnight, Jan 31/Feb 1, 2026" },
    { id: "auto_diesel", name: "Auto Diesel", price: 277.0, category: "retail", effectiveDate: "Effective Midnight, Jan 31/Feb 1, 2026" },
    { id: "super_diesel", name: "Super Diesel", price: 323.0, category: "retail", effectiveDate: "Effective Midnight, Jan 31/Feb 1, 2026" },
    { id: "lanka_kerosene", name: "Lanka Kerosene", price: 182.0, category: "retail", effectiveDate: "Effective Midnight, Jan 31/Feb 1, 2026" },
    { id: "industrial_kerosene", name: "Industrial Kerosene", price: 193.0, category: "retail", effectiveDate: "Effective Midnight, Jan 31/Feb 1, 2026" },
  ],
  industrial: [
    { id: "fuel_oil_super", name: "Lanka Fuel Oil Super", price: 194.0, category: "industrial", effectiveDate: "Effective Midnight, Jan 31/Feb 1, 2026" },
    { id: "fuel_oil_1500", name: "Lanka Fuel Oil 1500 Sec (High/Low Sulphur)", price: 250.0, category: "industrial", effectiveDate: "Effective Midnight, Jan 31/Feb 1, 2026" },
  ],
};

// Runs every day at midnight Sri Lanka time
exports.checkAndUpdateFuelPrices = functions.pubsub
  .schedule("0 0 * * *")
  .timeZone("Asia/Colombo")
  .onRun(async (context) => {
    await _syncPricesToFirestore();
    return null;
  });

// HTTP trigger - call to force update
exports.forceUpdatePrices = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  try {
    await _syncPricesToFirestore();
    res.json({ success: true, message: "Prices updated", timestamp: new Date().toISOString() });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// HTTP trigger - update a single price manually
exports.updateSinglePrice = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    res.status(204).send("");
    return;
  }
  const { id, price, effectiveDate, adminKey } = req.body;
  if (adminKey !== "PETROMIND_ADMIN_2026") {
    res.status(403).json({ error: "Unauthorized" });
    return;
  }
  if (!id || !price) {
    res.status(400).json({ error: "id and price required" });
    return;
  }
  try {
    await db.collection("fuel_prices_ceypetco").doc(id).update({
      price: parseFloat(price),
      effectiveDate: effectiveDate || "",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      source: "admin_update",
    });
    res.json({ success: true, id, price });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

async function _syncPricesToFirestore() {
  const allPrices = [...CURRENT_PRICES.retail, ...CURRENT_PRICES.industrial];
  const batch = db.batch();
  for (const item of allPrices) {
    const ref = db.collection("fuel_prices_ceypetco").doc(item.id);
    const existing = await ref.get();
    if (!existing.exists) {
      batch.set(ref, {
        name: item.name,
        price: item.price,
        category: item.category,
        effectiveDate: item.effectiveDate,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        source: "auto_sync",
      });
    }
  }
  await batch.commit();
}