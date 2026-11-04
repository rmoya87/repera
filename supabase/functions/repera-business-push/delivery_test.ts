import {
  aggregate,
  classifyApns,
  classifyFcm,
  constantTimeEqual,
  providerFor,
  reminderMessage,
} from "./delivery.ts";
import { base64UrlDecode } from "../_shared/jose.ts";
import { ApnsSender, FcmSender } from "./providers.ts";

function assert(value: unknown, message = "assertion failed"): asserts value {
  if (!value) throw new Error(message);
}
const eq = (a: unknown, b: unknown) => assert(JSON.stringify(a) === JSON.stringify(b), `${JSON.stringify(a)} !== ${JSON.stringify(b)}`);

const apnsToken = "a".repeat(64);
const fcmToken = "f".repeat(60) + ":APA91b" + "x".repeat(80);

Deno.test("routes iOS hex tokens to APNs and FCM tokens to FCM", () => {
  eq(providerFor({ id: "1", platform: "ios", token: apnsToken }), "apns");
  eq(providerFor({ id: "1", platform: "ios", token: fcmToken }), "fcm");
  eq(providerFor({ id: "1", platform: "android", token: fcmToken }), "fcm");
  eq(providerFor({ id: "1", platform: "android", token: apnsToken }), null);
  eq(providerFor({ id: "1", platform: "android", token: "short:token" }), null);
});

Deno.test("FCM unregistered tokens are invalid; quota and auth errors retry", () => {
  eq(classifyFcm(200, null).kind, "delivered");
  eq(classifyFcm(404, { error: { status: "NOT_FOUND" } }).kind, "invalid_token");
  eq(classifyFcm(400, { error: { details: [{ errorCode: "UNREGISTERED" }] } }).kind, "invalid_token");
  eq(
    classifyFcm(400, {
      error: { status: "INVALID_ARGUMENT", message: "The registration token is not a valid FCM registration token" },
    }).kind,
    "invalid_token",
  );
  eq(classifyFcm(400, { error: { status: "INVALID_ARGUMENT", message: "Invalid JSON payload" } }).kind, "retry");
  eq(classifyFcm(429, null).kind, "retry");
  eq(classifyFcm(503, null).kind, "retry");
  eq(classifyFcm(401, null).kind, "retry");
});

Deno.test("APNs 410/BadDeviceToken invalidate; provider-token errors retry", () => {
  eq(classifyApns(200, undefined).kind, "delivered");
  eq(classifyApns(410, "Unregistered").kind, "invalid_token");
  eq(classifyApns(400, "BadDeviceToken").kind, "invalid_token");
  eq(classifyApns(400, "DeviceTokenNotForTopic").kind, "invalid_token");
  eq(classifyApns(403, "ExpiredProviderToken").kind, "retry");
  eq(classifyApns(429, "TooManyRequests").kind, "retry");
});

Deno.test("aggregate never reports sent without a delivery", () => {
  eq(aggregate([]).outcome, "failed");
  eq(aggregate([{ kind: "not_configured", code: "X" }]).outcome, "skipped");
  eq(aggregate([{ kind: "invalid_token", code: "X" }, { kind: "not_configured", code: "Y" }]).outcome, "skipped");
  eq(aggregate([{ kind: "invalid_token", code: "X" }, { kind: "retry", code: "Y" }]).outcome, "retry");
  eq(aggregate([{ kind: "retry", code: "X" }, { kind: "delivered", code: "OK" }]).outcome, "sent");
  eq(aggregate([{ kind: "invalid_token", code: "X" }]).outcome, "failed");
});

Deno.test("reminder copy is bounded and has no personal data", () => {
  const msg = reminderMessage("class_reminder_60", "x".repeat(500));
  eq(msg.body.length, 80);
  eq(reminderMessage("appointment_reminder_60", null).title, "Tu cita empieza en 1 hora");
});

Deno.test("constant time comparison", async () => {
  assert(await constantTimeEqual("secret-value", "secret-value"));
  assert(!(await constantTimeEqual("secret-value", "secret-valuf")));
  assert(!(await constantTimeEqual("", "secret-value")));
});

Deno.test("providers stay disabled without valid secrets", () => {
  eq(FcmSender.fromEnv("", "repera"), null);
  eq(FcmSender.fromEnv("{not json", "repera"), null);
  eq(FcmSender.fromEnv(JSON.stringify({ client_email: "a@b", private_key: "k", token_uri: "https://evil" }), "p-1234"), null);
  eq(ApnsSender.fromEnv("", "", "", "com.app.repera"), null);
  eq(ApnsSender.fromEnv("ABCDEFGHIJ", "short", "-----BEGIN PRIVATE KEY-----", "com.app.repera"), null);
});

Deno.test("APNs provider token is a valid ES256 JWT", async () => {
  const pair = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign", "verify"]);
  const pkcs8 = new Uint8Array(await crypto.subtle.exportKey("pkcs8", pair.privateKey));
  const pem = `-----BEGIN PRIVATE KEY-----\n${btoa(String.fromCharCode(...pkcs8))}\n-----END PRIVATE KEY-----`;
  const sender = ApnsSender.fromEnv("ABCDEFGHIJ", "TEAM123456", pem, "com.app.repera");
  assert(sender);
  let captured: Request | null = null;
  const original = globalThis.fetch;
  globalThis.fetch = (input: string | URL | Request, init?: RequestInit) => {
    captured = new Request(input, init);
    return Promise.resolve(new Response(null, { status: 200 }));
  };
  try {
    const result = await sender.send({ id: "d", platform: "ios", token: apnsToken, environment: "sandbox" }, {
      title: "t",
      body: "b",
      collapseId: "c",
      data: {},
      expiresAt: Date.now() + 60_000,
    });
    eq(result.kind, "delivered");
  } finally {
    globalThis.fetch = original;
  }
  const req = captured as Request | null;
  assert(req);
  assert(req.url.startsWith("https://api.sandbox.push.apple.com/3/device/"));
  eq(req.headers.get("apns-topic"), "com.app.repera");
  const [h, c, s] = (req.headers.get("authorization") ?? "").replace("bearer ", "").split(".");
  eq(JSON.parse(new TextDecoder().decode(base64UrlDecode(h))), { alg: "ES256", kid: "ABCDEFGHIJ" });
  eq(JSON.parse(new TextDecoder().decode(base64UrlDecode(c))).iss, "TEAM123456");
  assert(
    await crypto.subtle.verify(
      { name: "ECDSA", hash: "SHA-256" },
      pair.publicKey,
      base64UrlDecode(s),
      new TextEncoder().encode(`${h}.${c}`),
    ),
  );
});
