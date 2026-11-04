import { importEs256PrivateKey, importRs256PrivateKey, signJwt } from "../_shared/jose.ts";
import { classifyApns, classifyFcm, type DeviceRow, type SendResult } from "./delivery.ts";

export type PushMessage = {
  title: string;
  body: string;
  collapseId: string;
  data: Record<string, string>;
  expiresAt: number;
};

type ServiceAccount = { client_email: string; private_key: string; project_id?: string; token_uri?: string };

const GOOGLE_TOKEN_URI = "https://oauth2.googleapis.com/token";
const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const REQUEST_TIMEOUT_MS = 10_000;

function withTimeout(init: RequestInit = {}): RequestInit {
  return { ...init, signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) };
}

export class FcmSender {
  #account: ServiceAccount;
  #projectId: string;
  #key: Promise<CryptoKey> | null = null;
  #accessToken: { value: string; expiresAt: number } | null = null;

  private constructor(account: ServiceAccount, projectId: string) {
    this.#account = account;
    this.#projectId = projectId;
  }

  static fromEnv(serviceAccountJson: string, projectId: string): FcmSender | null {
    if (!serviceAccountJson.trim()) return null;
    try {
      const account = JSON.parse(serviceAccountJson) as ServiceAccount;
      const project = projectId || account.project_id || "";
      if (!account.client_email || !account.private_key || !/^[a-z0-9-]{4,64}$/.test(project)) return null;
      if (account.token_uri && account.token_uri !== GOOGLE_TOKEN_URI) return null;
      return new FcmSender(account, project);
    } catch {
      return null;
    }
  }

  async #token(): Promise<string> {
    const now = Math.floor(Date.now() / 1000);
    if (this.#accessToken && this.#accessToken.expiresAt - 60 > now) return this.#accessToken.value;
    this.#key ??= importRs256PrivateKey(this.#account.private_key);
    const assertion = await signJwt({ alg: "RS256", typ: "JWT" }, {
      iss: this.#account.client_email,
      scope: FCM_SCOPE,
      aud: GOOGLE_TOKEN_URI,
      iat: now,
      exp: now + 3600,
    }, await this.#key);
    const res = await fetch(GOOGLE_TOKEN_URI, withTimeout({
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion }),
    }));
    if (!res.ok) throw new Error(`FCM_OAUTH_${res.status}`);
    const json = await res.json() as { access_token?: string; expires_in?: number };
    if (!json.access_token) throw new Error("FCM_OAUTH_EMPTY");
    this.#accessToken = { value: json.access_token, expiresAt: now + Math.min(json.expires_in ?? 3600, 3600) };
    return json.access_token;
  }

  async send(device: DeviceRow, message: PushMessage): Promise<SendResult> {
    let access: string;
    try {
      access = await this.#token();
    } catch {
      return { kind: "retry", code: "FCM_OAUTH" };
    }
    const ttlSeconds = Math.max(60, Math.floor((message.expiresAt - Date.now()) / 1000));
    try {
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${this.#projectId}/messages:send`,
        withTimeout({
          method: "POST",
          headers: { Authorization: `Bearer ${access}`, "content-type": "application/json" },
          body: JSON.stringify({
            message: {
              token: device.token,
              notification: { title: message.title, body: message.body },
              data: message.data,
              android: { priority: "high", ttl: `${ttlSeconds}s`, collapse_key: message.collapseId },
              apns: {
                headers: {
                  "apns-collapse-id": message.collapseId,
                  "apns-expiration": String(Math.floor(message.expiresAt / 1000)),
                },
              },
            },
          }),
        }),
      );
      if (res.status === 401) this.#accessToken = null;
      const body = res.ok ? null : await res.json().catch(() => null);
      return classifyFcm(res.status, body);
    } catch {
      return { kind: "retry", code: "FCM_NETWORK" };
    }
  }
}

export class ApnsSender {
  #keyId: string;
  #teamId: string;
  #bundleId: string;
  #key: Promise<CryptoKey>;
  #jwt: { value: string; issuedAt: number } | null = null;

  private constructor(keyId: string, teamId: string, bundleId: string, privateKey: string) {
    this.#keyId = keyId;
    this.#teamId = teamId;
    this.#bundleId = bundleId;
    this.#key = importEs256PrivateKey(privateKey);
    this.#key.catch(() => undefined);
  }

  static fromEnv(keyId: string, teamId: string, privateKey: string, bundleId: string): ApnsSender | null {
    if (!/^[A-Z0-9]{10}$/.test(keyId) || !/^[A-Z0-9]{10}$/.test(teamId) || !privateKey.includes("PRIVATE KEY")) {
      return null;
    }
    if (!/^[A-Za-z0-9.-]{3,155}$/.test(bundleId)) return null;
    return new ApnsSender(keyId, teamId, bundleId, privateKey);
  }

  async #providerToken(): Promise<string> {
    const now = Math.floor(Date.now() / 1000);
    // Apple rejects tokens refreshed more often than every 20 min and older than 60 min.
    if (this.#jwt && now - this.#jwt.issuedAt < 50 * 60) return this.#jwt.value;
    const value = await signJwt({ alg: "ES256", kid: this.#keyId }, { iss: this.#teamId, iat: now }, await this.#key);
    this.#jwt = { value, issuedAt: now };
    return value;
  }

  async send(device: DeviceRow, message: PushMessage): Promise<SendResult> {
    let jwt: string;
    try {
      jwt = await this.#providerToken();
    } catch {
      return { kind: "retry", code: "APNS_KEY" };
    }
    const host = device.environment === "sandbox" ? "api.sandbox.push.apple.com" : "api.push.apple.com";
    try {
      const res = await fetch(`https://${host}/3/device/${device.token}`, withTimeout({
        method: "POST",
        headers: {
          authorization: `bearer ${jwt}`,
          "apns-topic": this.#bundleId,
          "apns-push-type": "alert",
          "apns-priority": "10",
          "apns-collapse-id": message.collapseId.slice(0, 64),
          "apns-expiration": String(Math.floor(message.expiresAt / 1000)),
          "content-type": "application/json",
        },
        body: JSON.stringify({
          aps: { alert: { title: message.title, body: message.body }, sound: "default" },
          ...message.data,
        }),
      }));
      const reason = res.status === 200
        ? undefined
        : ((await res.json().catch(() => null)) as { reason?: string } | null)?.reason;
      if (reason === "ExpiredProviderToken" || reason === "InvalidProviderToken") this.#jwt = null;
      return classifyApns(res.status, reason);
    } catch {
      return { kind: "retry", code: "APNS_NETWORK" };
    }
  }
}
