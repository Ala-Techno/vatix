/**
 * Firestore Security Rules — Full Permission Matrix Tests
 * =======================================================
 * Project  : Vatix B2B Ordering & Ledger App
 * Coverage : users, invites, products, orders, ledger, accounts
 * Roles    : unauthenticated, pending retailer, blocked retailer,
 *            active retailer (wrong wholesaler), active retailer (correct wholesaler),
 *            wholesaler (owner), wholesaler (other)
 *
 * Prerequisites:
 *   firebase emulators:start --only firestore
 *   (or run via: firebase emulators:exec --only firestore "npx jest")
 */

const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const { readFileSync } = require("fs");
const { resolve } = require("path");

// ─────────────────────────────────────────────
// Test Environment Setup
// ─────────────────────────────────────────────

const PROJECT_ID = "vatix-rules-test";
const RULES_PATH = resolve(__dirname, "../firestore.rules");

/** @type {import("@firebase/rules-unit-testing").RulesTestEnvironment} */
let testEnv;

// ─── Shared IDs used across tests ───────────────────────────────────────────
const W1_UID       = "wholesaler-1";   // the owner wholesaler
const W2_UID       = "wholesaler-2";   // a different wholesaler
const R_ACTIVE_UID = "retailer-active"; // active retailer under W1
const R_PENDING_UID = "retailer-pending"; // pending retailer under W1
const R_BLOCKED_UID = "retailer-blocked"; // blocked retailer under W1
const R_OTHER_UID   = "retailer-other";   // active retailer under W2
const INVITE_CODE   = "INV-001";

// ─────────────────────────────────────────────
// Bootstrap
// ─────────────────────────────────────────────

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(RULES_PATH, "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });

  // Seed Firestore with the data our rules depend on (runs with admin privileges)
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    // Users
    await db.doc(`users/${W1_UID}`).set({
      role: "wholesaler", status: "active", wholesalerId: null,
      businessName: "W1 Wholesale", ownerName: "Owner1", phone: "111",
      city: "Sanaa", address: "Addr1", updatedAt: new Date(),
    });
    await db.doc(`users/${W2_UID}`).set({
      role: "wholesaler", status: "active", wholesalerId: null,
      businessName: "W2 Wholesale", ownerName: "Owner2", phone: "222",
      city: "Aden", address: "Addr2", updatedAt: new Date(),
    });
    await db.doc(`users/${R_ACTIVE_UID}`).set({
      role: "retailer", status: "active", wholesalerId: W1_UID,
      businessName: "Active Retail", ownerName: "Retailer1", phone: "333",
      city: "Taiz", address: "Addr3", inviteCode: INVITE_CODE, updatedAt: new Date(),
    });
    await db.doc(`users/${R_PENDING_UID}`).set({
      role: "retailer", status: "pending", wholesalerId: W1_UID,
      businessName: "Pending Retail", ownerName: "Retailer2", phone: "444",
      city: "Taiz", address: "Addr4", inviteCode: INVITE_CODE, updatedAt: new Date(),
    });
    await db.doc(`users/${R_BLOCKED_UID}`).set({
      role: "retailer", status: "blocked", wholesalerId: W1_UID,
      businessName: "Blocked Retail", ownerName: "Retailer3", phone: "555",
      city: "Taiz", address: "Addr5", inviteCode: INVITE_CODE, updatedAt: new Date(),
    });
    await db.doc(`users/${R_OTHER_UID}`).set({
      role: "retailer", status: "active", wholesalerId: W2_UID,
      businessName: "Other Retail", ownerName: "Retailer4", phone: "666",
      city: "Mukalla", address: "Addr6", inviteCode: "INV-002", updatedAt: new Date(),
    });

    // Invite codes
    await db.doc(`invites/${INVITE_CODE}`).set({
      wholesalerId: W1_UID, isActive: true, createdAt: new Date(),
    });
    await db.doc("invites/INV-002").set({
      wholesalerId: W2_UID, isActive: true, createdAt: new Date(),
    });
    await db.doc("invites/INV-INACTIVE").set({
      wholesalerId: W1_UID, isActive: false, createdAt: new Date(),
    });

    // Products
    await db.doc("products/prod-w1").set({
      wholesalerId: W1_UID, name: "Product A", price: 100,
      currency: "YER", stockQuantity: 50, isAvailable: true, updatedAt: new Date(),
    });
    await db.doc("products/prod-w2").set({
      wholesalerId: W2_UID, name: "Product B", price: 200,
      currency: "SAR", stockQuantity: 30, isAvailable: true, updatedAt: new Date(),
    });

    // Orders
    await db.doc("orders/order-pending").set({
      wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, status: "pending",
      items: [], totalAmount: 500, currency: "YER", createdAt: new Date(), updatedAt: new Date(),
    });
    await db.doc("orders/order-approved").set({
      wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, status: "approved",
      paymentType: "credit", items: [], totalAmount: 500, currency: "YER",
      createdAt: new Date(), updatedAt: new Date(), approvedAt: new Date(),
    });
    await db.doc("orders/order-w2").set({
      wholesalerId: W2_UID, retailerId: R_OTHER_UID, status: "pending",
      items: [], totalAmount: 300, currency: "SAR", createdAt: new Date(), updatedAt: new Date(),
    });

    // Ledger entries
    await db.doc("ledger/entry-1").set({
      wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, type: "DEBT",
      amount: 500, currency: "YER", createdBy: W1_UID, createdAt: new Date(),
    });

    // Accounts
    await db.doc(`accounts/${W1_UID}_${R_ACTIVE_UID}`).set({
      wholesalerId: W1_UID, retailerId: R_ACTIVE_UID,
      totalDebt: 500, totalPaid: 0, balance: 500, currency: "YER",
      updatedAt: new Date(),
    });
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

// Helper to clear Firestore between specific write tests
afterEach(async () => {
  await testEnv.clearFirestore();
  // Re-seed after clearing
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc(`users/${W1_UID}`).set({ role: "wholesaler", status: "active", wholesalerId: null, businessName: "W1 Wholesale", ownerName: "Owner1", phone: "111", city: "Sanaa", address: "Addr1", updatedAt: new Date() });
    await db.doc(`users/${W2_UID}`).set({ role: "wholesaler", status: "active", wholesalerId: null, businessName: "W2 Wholesale", ownerName: "Owner2", phone: "222", city: "Aden", address: "Addr2", updatedAt: new Date() });
    await db.doc(`users/${R_ACTIVE_UID}`).set({ role: "retailer", status: "active", wholesalerId: W1_UID, businessName: "Active Retail", ownerName: "Retailer1", phone: "333", city: "Taiz", address: "Addr3", inviteCode: INVITE_CODE, updatedAt: new Date() });
    await db.doc(`users/${R_PENDING_UID}`).set({ role: "retailer", status: "pending", wholesalerId: W1_UID, businessName: "Pending Retail", ownerName: "Retailer2", phone: "444", city: "Taiz", address: "Addr4", inviteCode: INVITE_CODE, updatedAt: new Date() });
    await db.doc(`users/${R_BLOCKED_UID}`).set({ role: "retailer", status: "blocked", wholesalerId: W1_UID, businessName: "Blocked Retail", ownerName: "Retailer3", phone: "555", city: "Taiz", address: "Addr5", inviteCode: INVITE_CODE, updatedAt: new Date() });
    await db.doc(`users/${R_OTHER_UID}`).set({ role: "retailer", status: "active", wholesalerId: W2_UID, businessName: "Other Retail", ownerName: "Retailer4", phone: "666", city: "Mukalla", address: "Addr6", inviteCode: "INV-002", updatedAt: new Date() });
    await db.doc(`invites/${INVITE_CODE}`).set({ wholesalerId: W1_UID, isActive: true, createdAt: new Date() });
    await db.doc("invites/INV-002").set({ wholesalerId: W2_UID, isActive: true, createdAt: new Date() });
    await db.doc("invites/INV-INACTIVE").set({ wholesalerId: W1_UID, isActive: false, createdAt: new Date() });
    await db.doc("products/prod-w1").set({ wholesalerId: W1_UID, name: "Product A", price: 100, currency: "YER", stockQuantity: 50, isAvailable: true, updatedAt: new Date() });
    await db.doc("products/prod-w2").set({ wholesalerId: W2_UID, name: "Product B", price: 200, currency: "SAR", stockQuantity: 30, isAvailable: true, updatedAt: new Date() });
    await db.doc("orders/order-pending").set({ wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, status: "pending", items: [], totalAmount: 500, currency: "YER", createdAt: new Date(), updatedAt: new Date() });
    await db.doc("orders/order-approved").set({ wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, status: "approved", paymentType: "credit", items: [], totalAmount: 500, currency: "YER", createdAt: new Date(), updatedAt: new Date(), approvedAt: new Date() });
    await db.doc("orders/order-w2").set({ wholesalerId: W2_UID, retailerId: R_OTHER_UID, status: "pending", items: [], totalAmount: 300, currency: "SAR", createdAt: new Date(), updatedAt: new Date() });
    await db.doc("ledger/entry-1").set({ wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, type: "DEBT", amount: 500, currency: "YER", createdBy: W1_UID, createdAt: new Date() });
    await db.doc(`accounts/${W1_UID}_${R_ACTIVE_UID}`).set({ wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, totalDebt: 500, totalPaid: 0, balance: 500, currency: "YER", updatedAt: new Date() });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: get a Firestore client for a given role
// ─────────────────────────────────────────────────────────────────────────────
function unauthenticated() {
  return testEnv.unauthenticatedContext().firestore();
}
function asWholesaler1() {
  return testEnv.authenticatedContext(W1_UID, { uid: W1_UID }).firestore();
}
function asWholesaler2() {
  return testEnv.authenticatedContext(W2_UID, { uid: W2_UID }).firestore();
}
function asActiveRetailer() {
  return testEnv.authenticatedContext(R_ACTIVE_UID, { uid: R_ACTIVE_UID }).firestore();
}
function asPendingRetailer() {
  return testEnv.authenticatedContext(R_PENDING_UID, { uid: R_PENDING_UID }).firestore();
}
function asBlockedRetailer() {
  return testEnv.authenticatedContext(R_BLOCKED_UID, { uid: R_BLOCKED_UID }).firestore();
}
function asOtherRetailer() {
  return testEnv.authenticatedContext(R_OTHER_UID, { uid: R_OTHER_UID }).firestore();
}

// ═════════════════════════════════════════════════════════════════════════════
// 1. INVITES COLLECTION
// ═════════════════════════════════════════════════════════════════════════════
describe("invites/{code}", () => {
  describe("get (single code lookup)", () => {
    it("✅ anyone (unauthenticated) can get a single invite", async () => {
      await assertSucceeds(unauthenticated().doc(`invites/${INVITE_CODE}`).get());
    });
    it("✅ wholesaler can get their own invite", async () => {
      await assertSucceeds(asWholesaler1().doc(`invites/${INVITE_CODE}`).get());
    });
    it("✅ active retailer can get invite (for registration flow)", async () => {
      await assertSucceeds(asActiveRetailer().doc(`invites/${INVITE_CODE}`).get());
    });
  });

  describe("list", () => {
    it("✅ wholesaler can list their own invites", async () => {
      const { collection, query, where } = require("firebase/firestore");
      const db = asWholesaler1();
      await assertSucceeds(
        db.collection("invites").where("wholesalerId", "==", W1_UID).get()
      );
    });
    it("❌ unauthenticated cannot list invites", async () => {
      await assertFails(unauthenticated().collection("invites").get());
    });
    it("❌ retailer cannot list invites", async () => {
      await assertFails(asActiveRetailer().collection("invites").get());
    });
    it("❌ wholesaler cannot list other wholesaler's invites", async () => {
      await assertFails(
        asWholesaler2().collection("invites").where("wholesalerId", "==", W1_UID).get()
      );
    });
  });

  describe("create", () => {
    it("✅ wholesaler can create their own invite", async () => {
      await assertSucceeds(
        asWholesaler1().doc("invites/NEW-CODE").set({
          wholesalerId: W1_UID, isActive: true, createdAt: new Date(),
        })
      );
    });
    it("❌ wholesaler cannot create invite for another wholesaler", async () => {
      await assertFails(
        asWholesaler1().doc("invites/FAKE-CODE").set({
          wholesalerId: W2_UID, isActive: true, createdAt: new Date(),
        })
      );
    });
    it("❌ retailer cannot create invites", async () => {
      await assertFails(
        asActiveRetailer().doc("invites/RETAIL-CODE").set({
          wholesalerId: W1_UID, isActive: true, createdAt: new Date(),
        })
      );
    });
    it("❌ unauthenticated cannot create invites", async () => {
      await assertFails(
        unauthenticated().doc("invites/ANON-CODE").set({
          wholesalerId: W1_UID, isActive: true, createdAt: new Date(),
        })
      );
    });
  });

  describe("delete", () => {
    it("❌ nobody can delete invites", async () => {
      await assertFails(asWholesaler1().doc(`invites/${INVITE_CODE}`).delete());
    });
    it("❌ even admin-role user cannot delete invites", async () => {
      await assertFails(asWholesaler2().doc("invites/INV-002").delete());
    });
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// 2. USERS COLLECTION
// ═════════════════════════════════════════════════════════════════════════════
describe("users/{uid}", () => {
  describe("read (own profile)", () => {
    it("✅ wholesaler reads own profile", async () => {
      await assertSucceeds(asWholesaler1().doc(`users/${W1_UID}`).get());
    });
    it("✅ active retailer reads own profile", async () => {
      await assertSucceeds(asActiveRetailer().doc(`users/${R_ACTIVE_UID}`).get());
    });
    it("✅ pending retailer reads own profile", async () => {
      await assertSucceeds(asPendingRetailer().doc(`users/${R_PENDING_UID}`).get());
    });
    it("❌ unauthenticated cannot read any user", async () => {
      await assertFails(unauthenticated().doc(`users/${W1_UID}`).get());
    });
  });

  describe("read (cross-party)", () => {
    it("✅ wholesaler reads their affiliated retailer profile", async () => {
      await assertSucceeds(asWholesaler1().doc(`users/${R_ACTIVE_UID}`).get());
    });
    it("✅ active retailer reads their wholesaler profile", async () => {
      await assertSucceeds(asActiveRetailer().doc(`users/${W1_UID}`).get());
    });
    it("❌ wholesaler cannot read unaffiliated retailer profile", async () => {
      await assertFails(asWholesaler2().doc(`users/${R_ACTIVE_UID}`).get());
    });
    it("❌ retailer cannot read unaffiliated wholesaler profile", async () => {
      await assertFails(asActiveRetailer().doc(`users/${W2_UID}`).get());
    });
  });

  describe("create (retailer self-registration)", () => {
    it("✅ new user can register as pending retailer with valid invite", async () => {
      const newUid = "new-retailer-uid";
      const ctx = testEnv.authenticatedContext(newUid, { uid: newUid });
      await assertSucceeds(
        ctx.firestore().doc(`users/${newUid}`).set({
          role: "retailer",
          status: "pending",
          wholesalerId: W1_UID,
          inviteCode: INVITE_CODE,
          businessName: "New Shop",
          ownerName: "New Owner",
          phone: "777",
          city: "Sanaa",
          address: "New Addr",
          updatedAt: new Date(),
        })
      );
    });
    it("❌ cannot register with inactive invite code", async () => {
      const newUid = "new-retailer-2";
      const ctx = testEnv.authenticatedContext(newUid, { uid: newUid });
      await assertFails(
        ctx.firestore().doc(`users/${newUid}`).set({
          role: "retailer", status: "pending", wholesalerId: W1_UID,
          inviteCode: "INV-INACTIVE", businessName: "Bad Shop",
          ownerName: "Bad Owner", phone: "888", city: "Sanaa",
          address: "Bad Addr", updatedAt: new Date(),
        })
      );
    });
    it("❌ cannot register as wholesaler role", async () => {
      const newUid = "new-wholesaler-attempt";
      const ctx = testEnv.authenticatedContext(newUid, { uid: newUid });
      await assertFails(
        ctx.firestore().doc(`users/${newUid}`).set({
          role: "wholesaler", status: "active", wholesalerId: null,
          inviteCode: INVITE_CODE, businessName: "Fake WS", updatedAt: new Date(),
        })
      );
    });
    it("❌ cannot self-register with status active (must be pending)", async () => {
      const newUid = "self-activate-attempt";
      const ctx = testEnv.authenticatedContext(newUid, { uid: newUid });
      await assertFails(
        ctx.firestore().doc(`users/${newUid}`).set({
          role: "retailer", status: "active", wholesalerId: W1_UID,
          inviteCode: INVITE_CODE, businessName: "Fake Active",
          ownerName: "Fake", phone: "999", city: "Sanaa",
          address: "Fake Addr", updatedAt: new Date(),
        })
      );
    });
    it("❌ cannot create profile for another UID", async () => {
      await assertFails(
        asActiveRetailer().doc(`users/${W1_UID}`).set({
          role: "retailer", status: "pending", wholesalerId: W1_UID,
          inviteCode: INVITE_CODE, businessName: "Impersonation",
          ownerName: "Fake", phone: "000", city: "City",
          address: "Addr", updatedAt: new Date(),
        })
      );
    });
  });

  describe("update (personal fields)", () => {
    it("✅ retailer updates own allowed fields", async () => {
      await assertSucceeds(
        asActiveRetailer().doc(`users/${R_ACTIVE_UID}`).update({
          businessName: "Updated Shop", updatedAt: new Date(),
        })
      );
    });
    it("❌ retailer cannot change their own role", async () => {
      await assertFails(
        asActiveRetailer().doc(`users/${R_ACTIVE_UID}`).update({
          role: "wholesaler",
        })
      );
    });
    it("❌ retailer cannot change their own status", async () => {
      await assertFails(
        asActiveRetailer().doc(`users/${R_ACTIVE_UID}`).update({
          status: "active", // even if already active — blocked field
        })
      );
    });
    it("❌ retailer cannot change their wholesalerId", async () => {
      await assertFails(
        asActiveRetailer().doc(`users/${R_ACTIVE_UID}`).update({
          wholesalerId: W2_UID,
        })
      );
    });
  });

  describe("update (wholesaler approves/blocks retailer)", () => {
    it("✅ wholesaler can activate a pending retailer", async () => {
      await assertSucceeds(
        asWholesaler1().doc(`users/${R_PENDING_UID}`).update({
          status: "active", updatedAt: new Date(),
        })
      );
    });
    it("✅ wholesaler can block an active retailer", async () => {
      await assertSucceeds(
        asWholesaler1().doc(`users/${R_ACTIVE_UID}`).update({
          status: "blocked", updatedAt: new Date(),
        })
      );
    });
    it("❌ wholesaler cannot change retailer's business name", async () => {
      await assertFails(
        asWholesaler1().doc(`users/${R_ACTIVE_UID}`).update({
          businessName: "Injected Name",
        })
      );
    });
    it("❌ wholesaler cannot approve another wholesaler's retailer", async () => {
      await assertFails(
        asWholesaler2().doc(`users/${R_PENDING_UID}`).update({
          status: "active", updatedAt: new Date(),
        })
      );
    });
  });

  describe("delete", () => {
    it("❌ nobody can delete a user document", async () => {
      await assertFails(asWholesaler1().doc(`users/${W1_UID}`).delete());
    });
    it("❌ retailer cannot delete own document", async () => {
      await assertFails(asActiveRetailer().doc(`users/${R_ACTIVE_UID}`).delete());
    });
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// 3. PRODUCTS COLLECTION
// ═════════════════════════════════════════════════════════════════════════════
describe("products/{id}", () => {
  describe("read", () => {
    it("✅ wholesaler reads own products", async () => {
      await assertSucceeds(asWholesaler1().doc("products/prod-w1").get());
    });
    it("✅ active retailer reads their wholesaler's products", async () => {
      await assertSucceeds(asActiveRetailer().doc("products/prod-w1").get());
    });
    it("❌ active retailer cannot read another wholesaler's products", async () => {
      await assertFails(asActiveRetailer().doc("products/prod-w2").get());
    });
    it("❌ pending retailer cannot read products", async () => {
      await assertFails(asPendingRetailer().doc("products/prod-w1").get());
    });
    it("❌ blocked retailer cannot read products", async () => {
      await assertFails(asBlockedRetailer().doc("products/prod-w1").get());
    });
    it("❌ unauthenticated cannot read products", async () => {
      await assertFails(unauthenticated().doc("products/prod-w1").get());
    });
    it("❌ wholesaler cannot read another wholesaler's products", async () => {
      await assertFails(asWholesaler2().doc("products/prod-w1").get());
    });
  });

  describe("create", () => {
    it("✅ wholesaler creates product under own ID with valid currency", async () => {
      await assertSucceeds(
        asWholesaler1().doc("products/new-prod").set({
          wholesalerId: W1_UID, name: "New Product", price: 150,
          currency: "YER", stockQuantity: 10, isAvailable: true, updatedAt: new Date(),
        })
      );
    });
    it("❌ wholesaler cannot create product for another wholesaler", async () => {
      await assertFails(
        asWholesaler1().doc("products/fake-prod").set({
          wholesalerId: W2_UID, name: "Fake Product", price: 100,
          currency: "YER", stockQuantity: 5, isAvailable: true, updatedAt: new Date(),
        })
      );
    });
    it("❌ wholesaler cannot create product with invalid currency", async () => {
      await assertFails(
        asWholesaler1().doc("products/bad-currency").set({
          wholesalerId: W1_UID, name: "Bad Product", price: 100,
          currency: "EUR", stockQuantity: 5, isAvailable: true, updatedAt: new Date(),
        })
      );
    });
    it("❌ active retailer cannot create products", async () => {
      await assertFails(
        asActiveRetailer().doc("products/retail-prod").set({
          wholesalerId: W1_UID, name: "Retail Product", price: 50,
          currency: "YER", stockQuantity: 3, isAvailable: true, updatedAt: new Date(),
        })
      );
    });
    it("❌ unauthenticated cannot create products", async () => {
      await assertFails(
        unauthenticated().doc("products/anon-prod").set({
          wholesalerId: W1_UID, name: "Anon Product", price: 50,
          currency: "YER", stockQuantity: 1, isAvailable: true, updatedAt: new Date(),
        })
      );
    });
  });

  describe("update", () => {
    it("✅ wholesaler updates own product", async () => {
      await assertSucceeds(
        asWholesaler1().doc("products/prod-w1").update({ name: "Updated A", updatedAt: new Date() })
      );
    });
    it("✅ active retailer updates stockQuantity (order placement flow)", async () => {
      await assertSucceeds(
        asActiveRetailer().doc("products/prod-w1").update({
          stockQuantity: 45, isAvailable: true, updatedAt: new Date(),
        })
      );
    });
    it("❌ active retailer cannot update product price", async () => {
      await assertFails(
        asActiveRetailer().doc("products/prod-w1").update({ price: 999 })
      );
    });
    it("❌ wholesaler cannot update another wholesaler's product", async () => {
      await assertFails(
        asWholesaler2().doc("products/prod-w1").update({ name: "Hijacked" })
      );
    });
    it("❌ pending retailer cannot update products", async () => {
      await assertFails(
        asPendingRetailer().doc("products/prod-w1").update({ stockQuantity: 1, isAvailable: true, updatedAt: new Date() })
      );
    });
  });

  describe("delete", () => {
    it("✅ wholesaler deletes own product", async () => {
      await assertSucceeds(asWholesaler1().doc("products/prod-w1").delete());
    });
    it("❌ retailer cannot delete products", async () => {
      await assertFails(asActiveRetailer().doc("products/prod-w1").delete());
    });
    it("❌ wholesaler cannot delete another wholesaler's product", async () => {
      await assertFails(asWholesaler2().doc("products/prod-w1").delete());
    });
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// 4. ORDERS COLLECTION
// ═════════════════════════════════════════════════════════════════════════════
describe("orders/{id}", () => {
  describe("read", () => {
    it("✅ retailer reads own order", async () => {
      await assertSucceeds(asActiveRetailer().doc("orders/order-pending").get());
    });
    it("✅ wholesaler reads order directed to them", async () => {
      await assertSucceeds(asWholesaler1().doc("orders/order-pending").get());
    });
    it("❌ other retailer cannot read this order", async () => {
      await assertFails(asOtherRetailer().doc("orders/order-pending").get());
    });
    it("❌ other wholesaler cannot read another wholesaler's order", async () => {
      await assertFails(asWholesaler2().doc("orders/order-pending").get());
    });
    it("❌ unauthenticated cannot read orders", async () => {
      await assertFails(unauthenticated().doc("orders/order-pending").get());
    });
    it("❌ pending retailer cannot read orders", async () => {
      await assertFails(asPendingRetailer().doc("orders/order-pending").get());
    });
  });

  describe("create", () => {
    it("✅ active retailer creates order for their wholesaler", async () => {
      await assertSucceeds(
        asActiveRetailer().doc("orders/new-order").set({
          wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, status: "pending",
          items: [{ productId: "prod-w1", qty: 2, price: 100, currency: "YER" }],
          totalAmount: 200, currency: "YER", createdAt: new Date(), updatedAt: new Date(),
        })
      );
    });
    it("❌ retailer cannot create order for different wholesaler", async () => {
      await assertFails(
        asActiveRetailer().doc("orders/fake-order").set({
          wholesalerId: W2_UID, retailerId: R_ACTIVE_UID, status: "pending",
          items: [], totalAmount: 0, currency: "YER", createdAt: new Date(), updatedAt: new Date(),
        })
      );
    });
    it("❌ retailer cannot create order with non-pending status", async () => {
      await assertFails(
        asActiveRetailer().doc("orders/approved-order").set({
          wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, status: "approved",
          items: [], totalAmount: 0, currency: "YER", createdAt: new Date(), updatedAt: new Date(),
        })
      );
    });
    it("❌ retailer cannot spoof retailerId", async () => {
      await assertFails(
        asActiveRetailer().doc("orders/spoofed-order").set({
          wholesalerId: W1_UID, retailerId: R_OTHER_UID, status: "pending",
          items: [], totalAmount: 0, currency: "YER", createdAt: new Date(), updatedAt: new Date(),
        })
      );
    });
    it("❌ pending retailer cannot create orders", async () => {
      await assertFails(
        asPendingRetailer().doc("orders/pending-order").set({
          wholesalerId: W1_UID, retailerId: R_PENDING_UID, status: "pending",
          items: [], totalAmount: 0, currency: "YER", createdAt: new Date(), updatedAt: new Date(),
        })
      );
    });
    it("❌ wholesaler cannot create orders", async () => {
      await assertFails(
        asWholesaler1().doc("orders/ws-order").set({
          wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, status: "pending",
          items: [], totalAmount: 0, currency: "YER", createdAt: new Date(), updatedAt: new Date(),
        })
      );
    });
  });

  describe("update (wholesaler approves)", () => {
    it("✅ wholesaler approves pending order (pending → approved + credit)", async () => {
      await assertSucceeds(
        asWholesaler1().doc("orders/order-pending").update({
          status: "approved", paymentType: "credit", updatedAt: new Date(), approvedAt: new Date(),
        })
      );
    });
    it("✅ wholesaler rejects pending order (pending → rejected)", async () => {
      await assertSucceeds(
        asWholesaler1().doc("orders/order-pending").update({
          status: "rejected", rejectionReason: "Out of stock", updatedAt: new Date(),
        })
      );
    });
    it("✅ wholesaler marks approved order as delivered", async () => {
      await assertSucceeds(
        asWholesaler1().doc("orders/order-approved").update({
          status: "delivered", updatedAt: new Date(), deliveredAt: new Date(),
        })
      );
    });
    it("❌ wholesaler cannot approve another wholesaler's order", async () => {
      await assertFails(
        asWholesaler1().doc("orders/order-w2").update({
          status: "approved", paymentType: "cash", updatedAt: new Date(), approvedAt: new Date(),
        })
      );
    });
    it("❌ wholesaler cannot skip approval (pending → delivered)", async () => {
      await assertFails(
        asWholesaler1().doc("orders/order-pending").update({
          status: "delivered", updatedAt: new Date(), deliveredAt: new Date(),
        })
      );
    });
    it("❌ wholesaler cannot inject extra fields on approval", async () => {
      await assertFails(
        asWholesaler1().doc("orders/order-pending").update({
          status: "approved", paymentType: "credit",
          updatedAt: new Date(), approvedAt: new Date(),
          maliciousField: "injected",
        })
      );
    });
  });

  describe("update (retailer cancels)", () => {
    it("✅ retailer cancels own pending order", async () => {
      await assertSucceeds(
        asActiveRetailer().doc("orders/order-pending").update({
          status: "cancelled", updatedAt: new Date(),
        })
      );
    });
    it("❌ retailer cannot cancel an already-approved order", async () => {
      await assertFails(
        asActiveRetailer().doc("orders/order-approved").update({
          status: "cancelled", updatedAt: new Date(),
        })
      );
    });
    it("❌ retailer cannot change status to anything other than cancelled", async () => {
      await assertFails(
        asActiveRetailer().doc("orders/order-pending").update({
          status: "delivered", updatedAt: new Date(),
        })
      );
    });
  });

  describe("delete", () => {
    it("❌ nobody can delete orders", async () => {
      await assertFails(asWholesaler1().doc("orders/order-pending").delete());
    });
    it("❌ retailer cannot delete own order", async () => {
      await assertFails(asActiveRetailer().doc("orders/order-pending").delete());
    });
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// 5. LEDGER COLLECTION
// ═════════════════════════════════════════════════════════════════════════════
describe("ledger/{id}", () => {
  describe("read", () => {
    it("✅ wholesaler reads ledger entry for their retailer", async () => {
      await assertSucceeds(asWholesaler1().doc("ledger/entry-1").get());
    });
    it("✅ retailer reads their own ledger entry", async () => {
      await assertSucceeds(asActiveRetailer().doc("ledger/entry-1").get());
    });
    it("❌ another wholesaler cannot read this ledger entry", async () => {
      await assertFails(asWholesaler2().doc("ledger/entry-1").get());
    });
    it("❌ unauthenticated cannot read ledger", async () => {
      await assertFails(unauthenticated().doc("ledger/entry-1").get());
    });
    it("❌ pending retailer cannot read ledger", async () => {
      await assertFails(asPendingRetailer().doc("ledger/entry-1").get());
    });
  });

  describe("create", () => {
    it("✅ wholesaler creates valid DEBT ledger entry for affiliated retailer", async () => {
      await assertSucceeds(
        asWholesaler1().doc("ledger/new-entry").set({
          wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, type: "DEBT",
          amount: 300, currency: "SAR", createdBy: W1_UID, createdAt: new Date(),
        })
      );
    });
    it("✅ wholesaler creates valid PAYMENT ledger entry", async () => {
      await assertSucceeds(
        asWholesaler1().doc("ledger/payment-entry").set({
          wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, type: "PAYMENT",
          amount: 100, currency: "USD", createdBy: W1_UID, createdAt: new Date(),
        })
      );
    });
    it("❌ wholesaler cannot create entry for non-affiliated retailer", async () => {
      await assertFails(
        asWholesaler1().doc("ledger/bad-entry").set({
          wholesalerId: W1_UID, retailerId: R_OTHER_UID, type: "DEBT",
          amount: 100, currency: "YER", createdBy: W1_UID, createdAt: new Date(),
        })
      );
    });
    it("❌ wholesaler cannot spoof wholesalerId", async () => {
      await assertFails(
        asWholesaler2().doc("ledger/spoof-entry").set({
          wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, type: "DEBT",
          amount: 100, currency: "YER", createdBy: W2_UID, createdAt: new Date(),
        })
      );
    });
    it("❌ cannot create entry with invalid type", async () => {
      await assertFails(
        asWholesaler1().doc("ledger/bad-type").set({
          wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, type: "REFUND",
          amount: 100, currency: "YER", createdBy: W1_UID, createdAt: new Date(),
        })
      );
    });
    it("❌ cannot create entry with zero amount", async () => {
      await assertFails(
        asWholesaler1().doc("ledger/zero-amount").set({
          wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, type: "DEBT",
          amount: 0, currency: "YER", createdBy: W1_UID, createdAt: new Date(),
        })
      );
    });
    it("❌ cannot create entry with negative amount", async () => {
      await assertFails(
        asWholesaler1().doc("ledger/negative-amount").set({
          wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, type: "DEBT",
          amount: -50, currency: "YER", createdBy: W1_UID, createdAt: new Date(),
        })
      );
    });
    it("❌ cannot create entry with invalid currency", async () => {
      await assertFails(
        asWholesaler1().doc("ledger/bad-currency").set({
          wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, type: "DEBT",
          amount: 100, currency: "GBP", createdBy: W1_UID, createdAt: new Date(),
        })
      );
    });
    it("❌ retailer cannot create ledger entries", async () => {
      await assertFails(
        asActiveRetailer().doc("ledger/retailer-entry").set({
          wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, type: "PAYMENT",
          amount: 100, currency: "YER", createdBy: R_ACTIVE_UID, createdAt: new Date(),
        })
      );
    });
    it("❌ unauthenticated cannot create ledger entries", async () => {
      await assertFails(
        unauthenticated().doc("ledger/anon-entry").set({
          wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, type: "DEBT",
          amount: 100, currency: "YER", createdBy: "anon", createdAt: new Date(),
        })
      );
    });
  });

  describe("update / delete (immutable ledger)", () => {
    it("❌ wholesaler cannot update a ledger entry", async () => {
      await assertFails(asWholesaler1().doc("ledger/entry-1").update({ amount: 999 }));
    });
    it("❌ retailer cannot update a ledger entry", async () => {
      await assertFails(asActiveRetailer().doc("ledger/entry-1").update({ amount: 0 }));
    });
    it("❌ wholesaler cannot delete a ledger entry", async () => {
      await assertFails(asWholesaler1().doc("ledger/entry-1").delete());
    });
    it("❌ retailer cannot delete a ledger entry", async () => {
      await assertFails(asActiveRetailer().doc("ledger/entry-1").delete());
    });
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// 6. ACCOUNTS COLLECTION
// ═════════════════════════════════════════════════════════════════════════════
describe("accounts/{id}", () => {
  const ACCOUNT_ID = `${W1_UID}_${R_ACTIVE_UID}`;

  describe("read", () => {
    it("✅ wholesaler reads account for their retailer", async () => {
      await assertSucceeds(asWholesaler1().doc(`accounts/${ACCOUNT_ID}`).get());
    });
    it("✅ retailer reads their own account", async () => {
      await assertSucceeds(asActiveRetailer().doc(`accounts/${ACCOUNT_ID}`).get());
    });
    it("❌ another wholesaler cannot read this account", async () => {
      await assertFails(asWholesaler2().doc(`accounts/${ACCOUNT_ID}`).get());
    });
    it("❌ another retailer cannot read this account", async () => {
      await assertFails(asOtherRetailer().doc(`accounts/${ACCOUNT_ID}`).get());
    });
    it("❌ unauthenticated cannot read accounts", async () => {
      await assertFails(unauthenticated().doc(`accounts/${ACCOUNT_ID}`).get());
    });
    it("❌ pending retailer cannot read accounts", async () => {
      await assertFails(asPendingRetailer().doc(`accounts/${ACCOUNT_ID}`).get());
    });
  });

  describe("write (wholesaler updates/merges balance)", () => {
    it("✅ wholesaler updates account balance for affiliated retailer", async () => {
      await assertSucceeds(
        asWholesaler1().doc(`accounts/${ACCOUNT_ID}`).set({
          wholesalerId: W1_UID, retailerId: R_ACTIVE_UID,
          totalDebt: 800, totalPaid: 300, balance: 500, currency: "YER", updatedAt: new Date(),
        })
      );
    });
    it("❌ wholesaler cannot update account with wrong wholesalerId", async () => {
      await assertFails(
        asWholesaler2().doc(`accounts/${ACCOUNT_ID}`).set({
          wholesalerId: W2_UID, retailerId: R_ACTIVE_UID,
          totalDebt: 100, totalPaid: 0, balance: 100, currency: "YER", updatedAt: new Date(),
        })
      );
    });
    it("❌ wholesaler cannot spoof wholesalerId", async () => {
      await assertFails(
        asWholesaler1().doc(`accounts/${ACCOUNT_ID}`).set({
          wholesalerId: W2_UID, retailerId: R_ACTIVE_UID,
          totalDebt: 100, totalPaid: 0, balance: 100, currency: "YER", updatedAt: new Date(),
        })
      );
    });
    it("❌ retailer cannot write to accounts", async () => {
      await assertFails(
        asActiveRetailer().doc(`accounts/${ACCOUNT_ID}`).update({ balance: 0 })
      );
    });
    it("❌ unauthenticated cannot write to accounts", async () => {
      await assertFails(
        unauthenticated().doc(`accounts/${ACCOUNT_ID}`).set({
          wholesalerId: W1_UID, retailerId: R_ACTIVE_UID, totalDebt: 0, balance: 0, updatedAt: new Date(),
        })
      );
    });
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// 7. DEFAULT DENY — arbitrary paths
// ═════════════════════════════════════════════════════════════════════════════
describe("Default deny (catch-all rule)", () => {
  it("❌ unauthenticated cannot read arbitrary collection", async () => {
    await assertFails(unauthenticated().doc("random/doc").get());
  });
  it("❌ wholesaler cannot read arbitrary collection", async () => {
    await assertFails(asWholesaler1().doc("admin/secret").get());
  });
  it("❌ retailer cannot read arbitrary collection", async () => {
    await assertFails(asActiveRetailer().doc("config/settings").get());
  });
  it("❌ nobody can write to arbitrary paths", async () => {
    await assertFails(
      asWholesaler1().doc("system/config").set({ hack: true })
    );
  });
});
