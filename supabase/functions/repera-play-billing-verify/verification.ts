import {grantsPro, mapSubscription, sha256, type PlaySubscription} from "./policy.ts";
export type VerificationDependencies = {
  getSubscription: (token: string) => Promise<PlaySubscription | null>;
  claim: (record: {tokenHash: string; owner: string; linkedHash: string | null;
    product: string | null; state: string; expiry: string | null}) => Promise<boolean>;
  acknowledge: (token: string, product: string) => Promise<void>;
};
export class OwnershipError extends Error {}

/** Completed replacements may supersede the prior token via linkedPurchaseToken. */
export function maySupersedeLinkedPurchase(state: string | undefined): boolean {
  switch (state) {
    case "SUBSCRIPTION_STATE_ACTIVE":
    case "SUBSCRIPTION_STATE_CANCELED":
    case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD":
    case "SUBSCRIPTION_STATE_ON_HOLD":
    case "SUBSCRIPTION_STATE_PAUSED":
    case "SUBSCRIPTION_STATE_EXPIRED":
      return true;
    default:
      // PENDING / PENDING_PURCHASE_CANCELED / UNSPECIFIED: prior purchase still counts.
      return false;
  }
}

/** Google: for canceled pending purchase, consult linkedPurchaseToken for existing sub. */
export function shouldConsultLinkedPurchase(state: string | undefined): boolean {
  return state === "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED" ||
    state === "SUBSCRIPTION_STATE_PENDING";
}

/**
 * Pro follows the Play purchase (Google account on device), not a permanent
 * Supabase UUID bind — same policy as StoreKit ↔ Apple ID after hard delete.
 *
 * `obfuscatedAccountId` is still set at purchase (SHA-256 of the then-current
 * UUID) for Play Console correlation. After delete+recreate that hash will not
 * match the new UUID; verify must still succeed when the live claim allows it.
 *
 * Anti-hijack among *live* owners is enforced by `claim_play_subscription`
 * (reject if another non-null owner holds the token; reclaim when owner is NULL
 * after auth.users hard delete via ON DELETE SET NULL).
 *
 * `linkedPurchaseToken` only marks the prior hash superseded on a *completed*
 * replacement. `PENDING_PURCHASE_CANCELED` (and pending) consults the linked
 * subscription instead of invalidating a still-paid prior purchase.
 */
export async function verifySubscription(
  userId: string,
  purchaseToken: string,
  deps: VerificationDependencies,
  now = Date.now(),
  seenTokens: ReadonlySet<string> = new Set(),
) {
  if (seenTokens.has(purchaseToken)) {
    return {status: "free", productId: null, expiryEpochMs: null,
      acknowledged: false, playState: "LINK_CYCLE"};
  }
  const seen = new Set(seenTokens);
  seen.add(purchaseToken);

  const sub = await deps.getSubscription(purchaseToken);
  if (!sub) return {status: "free", productId: null, expiryEpochMs: null,
    acknowledged: false, playState: "NOT_FOUND"};

  // Canceled/pending replacement: do not supersede; follow Google's linked token.
  if (shouldConsultLinkedPurchase(sub.subscriptionState) && sub.linkedPurchaseToken) {
    return verifySubscription(userId, sub.linkedPurchaseToken, deps, now, seen);
  }

  const mapped = mapSubscription(sub, now);
  const linkedHash = sub.linkedPurchaseToken && maySupersedeLinkedPurchase(sub.subscriptionState)
    ? await sha256(sub.linkedPurchaseToken)
    : null;
  const claimed = await deps.claim({
    tokenHash: await sha256(purchaseToken), owner: userId,
    linkedHash,
    product: mapped.productId, state: sub.subscriptionState ?? "UNKNOWN",
    expiry: mapped.expiryEpochMs === null ? null : new Date(mapped.expiryEpochMs).toISOString(),
  });
  if (!claimed) throw new OwnershipError("Purchase already bound or superseded");
  let acknowledged = sub.acknowledgementState === "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED";
  if (grantsPro(mapped) && !acknowledged) {
    await deps.acknowledge(purchaseToken, mapped.productId!);
    acknowledged = true;
  }
  return {...mapped, acknowledged, playState: sub.subscriptionState ?? "UNKNOWN"};
}
