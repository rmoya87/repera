import {grantsPro, mapSubscription, sha256, type PlaySubscription} from "./policy.ts";
export type VerificationDependencies = {
  getSubscription: (token: string) => Promise<PlaySubscription | null>;
  claim: (record: {tokenHash: string; owner: string; linkedHash: string | null;
    product: string | null; state: string; expiry: string | null}) => Promise<boolean>;
  acknowledge: (token: string, product: string) => Promise<void>;
};
export class OwnershipError extends Error {}
export async function verifySubscription(
  userId: string, purchaseToken: string, deps: VerificationDependencies, now = Date.now()
) {
  const sub = await deps.getSubscription(purchaseToken);
  if (!sub) return {status: "free", productId: null, expiryEpochMs: null,
    acknowledged: false, playState: "NOT_FOUND"};
  // Fail closed for legacy/unbound purchases. No paid products existed at rollout.
  const expectedAccount = await sha256(userId.toLowerCase());
  if (sub.externalAccountIdentifiers?.obfuscatedExternalAccountId !== expectedAccount) {
    throw new OwnershipError("Purchase account mismatch");
  }
  const mapped = mapSubscription(sub, now);
  const claimed = await deps.claim({
    tokenHash: await sha256(purchaseToken), owner: userId,
    linkedHash: sub.linkedPurchaseToken ? await sha256(sub.linkedPurchaseToken) : null,
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
