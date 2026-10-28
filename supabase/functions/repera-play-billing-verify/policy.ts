export const MONTHLY = "com.app.repera.premium.monthly";
export const ANNUAL = "com.app.repera.premium.yearly";
export const PRODUCTS = new Set([MONTHLY, ANNUAL]);
export type PlaySubscription = {
  subscriptionState?: string;
  acknowledgementState?: string;
  linkedPurchaseToken?: string;
  externalAccountIdentifiers?: { obfuscatedExternalAccountId?: string };
  lineItems?: { productId?: string; expiryTime?: string }[];
};
export type Entitlement = {
  status: string;
  productId: string | null;
  expiryEpochMs: number | null;
};
export function mapSubscription(sub: PlaySubscription, now = Date.now()): Entitlement {
  // Only Play's product ID is authoritative. Never fall back to a client hint.
  const item = sub.lineItems?.filter(x => PRODUCTS.has(x.productId ?? ""))
    .sort((a,b) => Date.parse(b.expiryTime ?? "") - Date.parse(a.expiryTime ?? ""))[0];
  const productId = item?.productId ?? null;
  const parsed = Date.parse(item?.expiryTime ?? "");
  const expiryEpochMs = Number.isFinite(parsed) ? parsed : null;
  const result = (status: string): Entitlement => ({status, productId, expiryEpochMs});
  if (!productId) return result("free");
  switch (sub.subscriptionState) {
    case "SUBSCRIPTION_STATE_EXPIRED": return result("expired");
    case "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED": return result("revoked");
    case "SUBSCRIPTION_STATE_ON_HOLD":
    case "SUBSCRIPTION_STATE_PAUSED":
    case "SUBSCRIPTION_STATE_PENDING": return result("free");
    case "SUBSCRIPTION_STATE_ACTIVE":
    case "SUBSCRIPTION_STATE_CANCELED":
    case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD":
      if (expiryEpochMs === null || expiryEpochMs <= now) return result("expired");
      if (sub.subscriptionState === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD") return result("gracePeriod");
      return result(productId === ANNUAL ? "proAnnual" : "proMonthly");
    default: return result("free");
  }
}
export const grantsPro = (e: Entitlement) =>
  ["proMonthly", "proAnnual", "gracePeriod"].includes(e.status);
export async function sha256(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return Array.from(new Uint8Array(digest), b => b.toString(16).padStart(2, "0")).join("");
}
