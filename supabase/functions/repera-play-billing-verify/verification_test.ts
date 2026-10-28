import {ANNUAL, MONTHLY, mapSubscription, sha256, grantsPro} from "./policy.ts";
import {
  OwnershipError,
  maySupersedeLinkedPurchase,
  shouldConsultLinkedPurchase,
  verifySubscription,
  type VerificationDependencies,
} from "./verification.ts";
function assert(value: unknown, message = "assertion failed"): asserts value {
  if (!value) throw new Error(message);
}
const now = Date.parse("2026-10-28T16:00:00Z");
const future = new Date(now + 100000).toISOString();
const base = {subscriptionState: "SUBSCRIPTION_STATE_ACTIVE", lineItems: [{productId: MONTHLY, expiryTime: future}]};
for (const state of ["ON_HOLD", "PAUSED", "PENDING", "UNSPECIFIED", "PENDING_PURCHASE_CANCELED", "EXPIRED"]) {
  Deno.test(`${state} never grants Pro even with future expiry`, () => {
    assert(!grantsPro(mapSubscription({...base, subscriptionState: `SUBSCRIPTION_STATE_${state}`}, now)));
  });
}
for (const state of ["ACTIVE", "CANCELED", "IN_GRACE_PERIOD"]) {
  Deno.test(`${state} valid product with future expiry grants, missing/past expiry does not`, () => {
    assert(grantsPro(mapSubscription({...base, subscriptionState: `SUBSCRIPTION_STATE_${state}`}, now)));
    for (const expiryTime of [undefined, "invalid", new Date(now).toISOString()]) {
      assert(!grantsPro(mapSubscription({...base, subscriptionState: `SUBSCRIPTION_STATE_${state}`,
        lineItems: [{productId: MONTHLY, expiryTime}]}, now)));
    }
  });
}
Deno.test("unknown product cannot be promoted by client hint", () => {
  assert(mapSubscription({...base, lineItems:[{productId:"unknown",expiryTime:future}]}, now).status === "free");
});
Deno.test("annual and real grace map distinctly", () => {
  assert(mapSubscription({...base,lineItems:[{productId:ANNUAL,expiryTime:future}]},now).status === "proAnnual");
  assert(mapSubscription({...base,subscriptionState:"SUBSCRIPTION_STATE_IN_GRACE_PERIOD"},now).status === "gracePeriod");
});
const owner = "00000000-0000-0000-0000-000000000001";
const recreated = "00000000-0000-0000-0000-000000000099";
async function fixtures() {
  const claims: unknown[] = []; const acks: unknown[] = [];
  const sub = {...base, externalAccountIdentifiers:{obfuscatedExternalAccountId:await sha256(owner)},
    acknowledgementState:"ACKNOWLEDGEMENT_STATE_PENDING"};
  const deps: VerificationDependencies = {
    getSubscription: async () => sub,
    claim: async record => {claims.push(record);return true;},
    acknowledge: async (token,product) => {acks.push({token,product});},
  };
  return {sub,deps,claims,acks};
}
Deno.test("verify binds hashed token then backend acknowledges before granting", async () => {
  const f=await fixtures();
  const result=await verifySubscription(owner,"token",f.deps,now);
  assert(result.status === "proMonthly" && result.acknowledged);
  assert(f.claims.length===1 && f.acks.length===1);
  assert((f.claims[0] as {tokenHash:string}).tokenHash === await sha256("token"));
});
Deno.test("Apple parity: stale or absent obfuscatedAccountId still claims after recreate", async () => {
  // Purchase was bound to the deleted UUID hash; new auth.users id differs.
  for (const account of [undefined, await sha256(owner), await sha256("other-deleted")]) {
    const f = await fixtures();
    if (account === undefined) {
      delete (f.sub as {externalAccountIdentifiers?: unknown}).externalAccountIdentifiers;
    } else {
      f.sub.externalAccountIdentifiers!.obfuscatedExternalAccountId = account;
    }
    const result = await verifySubscription(recreated, "token", f.deps, now);
    assert(result.status === "proMonthly" && result.acknowledged);
    assert(f.claims.length === 1);
    assert((f.claims[0] as {owner: string}).owner === recreated);
    assert(f.acks.length === 1);
  }
});
Deno.test("ownership conflict and superseded token reject without acknowledgement",async()=>{
  const f=await fixtures();f.deps.claim=async()=>false;
  let rejected=false;try{await verifySubscription(owner,"token",f.deps,now);}catch(e){rejected=e instanceof OwnershipError;}
  assert(rejected && f.acks.length===0);
});
Deno.test("completed replacement passes linked hash to atomic claim",async()=>{
  const f=await fixtures();f.deps.getSubscription=async()=>({...f.sub,linkedPurchaseToken:"old"});
  await verifySubscription(owner,"new",f.deps,now);
  assert((f.claims[0] as {linkedHash:string}).linkedHash===await sha256("old"));
  assert(maySupersedeLinkedPurchase("SUBSCRIPTION_STATE_ACTIVE"));
  assert(!maySupersedeLinkedPurchase("SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED"));
  assert(shouldConsultLinkedPurchase("SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED"));
});
Deno.test("PENDING_PURCHASE_CANCELED consults linked prior and never supersedes it", async () => {
  const prior = {...base, acknowledgementState: "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED"};
  const canceled = {
    ...base,
    subscriptionState: "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED",
    linkedPurchaseToken: "prior-active",
    acknowledgementState: "ACKNOWLEDGEMENT_STATE_PENDING",
  };
  const claims: unknown[] = [];
  const acks: unknown[] = [];
  const deps: VerificationDependencies = {
    getSubscription: async (token) => token === "canceled-attempt" ? canceled : token === "prior-active" ? prior : null,
    claim: async (record) => { claims.push(record); return true; },
    acknowledge: async (token, product) => { acks.push({token, product}); },
  };
  const result = await verifySubscription(owner, "canceled-attempt", deps, now);
  assert(result.status === "proMonthly" && result.acknowledged);
  assert(result.playState === "SUBSCRIPTION_STATE_ACTIVE");
  assert(claims.length === 1);
  assert((claims[0] as {tokenHash: string}).tokenHash === await sha256("prior-active"));
  assert((claims[0] as {linkedHash: string | null}).linkedHash === null);
  assert(acks.length === 0);
});
Deno.test("PENDING with linked also follows prior without superseding", async () => {
  const prior = {...base, acknowledgementState: "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED"};
  const pending = {
    ...base,
    subscriptionState: "SUBSCRIPTION_STATE_PENDING",
    linkedPurchaseToken: "prior-active",
  };
  const claims: unknown[] = [];
  const deps: VerificationDependencies = {
    getSubscription: async (token) => token === "upgrade-pending" ? pending : prior,
    claim: async (record) => { claims.push(record); return true; },
    acknowledge: async () => {},
  };
  const result = await verifySubscription(owner, "upgrade-pending", deps, now);
  assert(result.status === "proMonthly");
  assert(claims.length === 1);
  assert((claims[0] as {linkedHash: string | null}).linkedHash === null);
});
Deno.test("ack failure fails closed and next verification retries",async()=>{
  const f=await fixtures();let calls=0;
  f.deps.acknowledge=async()=>{calls++;if(calls===1)throw new Error("network");};
  let rejected=false;try{await verifySubscription(owner,"token",f.deps,now);}catch{rejected=true;}
  assert(rejected);assert((await verifySubscription(owner,"token",f.deps,now)).acknowledged && calls===2);
});
Deno.test("already acknowledged does not acknowledge twice; hold never acknowledges",async()=>{
  const f=await fixtures();f.sub.acknowledgementState="ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED";
  await verifySubscription(owner,"token",f.deps,now);assert(f.acks.length===0);
  f.sub.subscriptionState="SUBSCRIPTION_STATE_ON_HOLD";f.sub.acknowledgementState="ACKNOWLEDGEMENT_STATE_PENDING";
  assert((await verifySubscription(owner,"token",f.deps,now)).status==="free" && f.acks.length===0);
});
Deno.test("404 returns free without ownership claim or acknowledgement",async()=>{
 const f=await fixtures();f.deps.getSubscription=async()=>null;
 assert((await verifySubscription(owner,"missing",f.deps,now)).status==="free" && f.claims.length===0 && f.acks.length===0);
});
Deno.test("account hash matches cross-platform known vector",async()=>{
 assert(await sha256(owner)==="7ac1b8d7010bb6cd3a3e84e7f90136b880bbc899e428ece49333372911ab9052");
});
