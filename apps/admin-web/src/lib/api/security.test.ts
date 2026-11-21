import { describe, expect, it, vi } from "vitest";
import { ApiClient } from "./client";
import { ApiError, ConfigError } from "./errors";
import { errorMessage } from "./messages";

const json = (status: number, body?: unknown) =>
  new Response(body === undefined ? null : JSON.stringify(body), { status });

const loggedIn = async (fetchImpl: typeof fetch, onSessionLost?: () => void) => {
  const client = new ApiClient({ baseUrl: "http://api", requireHttps: false, fetchImpl, onSessionLost });
  await client.login("p", "w");
  return client;
};

describe("session handling", () => {
  it.each(["UNAUTHENTICATED", "TOKEN_REVOKED"])("drops the session on a %s response", async (code) => {
    const lost = vi.fn();
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce(json(200, { accessToken: "a", refreshToken: "r" }))
      .mockResolvedValueOnce(json(401, { code }));
    const client = await loggedIn(fetchImpl, lost);
    await expect(client.me()).rejects.toMatchObject({ code });
    expect(lost).toHaveBeenCalledTimes(1);
    expect(client.isAuthenticated).toBe(false);
  });

  it("drops the session when a 401 persists after a successful renewal", async () => {
    const lost = vi.fn();
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce(json(200, { accessToken: "a1", refreshToken: "r1" }))
      .mockResolvedValueOnce(json(401, { code: "TOKEN_EXPIRED" }))
      .mockResolvedValueOnce(json(200, { accessToken: "a2", refreshToken: "r2" }))
      .mockResolvedValueOnce(json(401, { code: "UNAUTHENTICATED" }));
    const client = await loggedIn(fetchImpl, lost);
    await expect(client.me()).rejects.toBeInstanceOf(ApiError);
    expect(lost).toHaveBeenCalled();
    expect(client.isAuthenticated).toBe(false);
  });

  it("does not call the server for an authenticated route without a session", async () => {
    const fetchImpl = vi.fn();
    const client = new ApiClient({ baseUrl: "http://api", requireHttps: false, fetchImpl });
    await expect(client.createCategory({ name: "x", order: 0, family: "Vente", minVerificationLevel: "N0" })).rejects.toMatchObject({
      code: "UNAUTHENTICATED",
    });
    expect(fetchImpl).not.toHaveBeenCalled();
  });

  it("clears local tokens at logout even if the server call fails", async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce(json(200, { accessToken: "a", refreshToken: "r" }))
      .mockRejectedValueOnce(new TypeError("offline"));
    const client = await loggedIn(fetchImpl);
    await client.logout().catch(() => undefined);
    expect(client.isAuthenticated).toBe(false);
  });
});

describe("transport safety", () => {
  it("never sends credentials over http when HTTPS is required", async () => {
    const fetchImpl = vi.fn();
    const client = new ApiClient({ baseUrl: "http://api.example.com/api/v1", requireHttps: true, fetchImpl });
    const error = await client.login("+242060000000", "secret").catch((e) => e);
    expect(error).toBeInstanceOf(ConfigError);
    expect(fetchImpl).not.toHaveBeenCalled();
    expect(errorMessage(error)).toContain("pas configurée");
  });

  it("fails closed when the API URL is not configured", async () => {
    const fetchImpl = vi.fn();
    const client = new ApiClient({ baseUrl: "", requireHttps: true, fetchImpl });
    await expect(client.login("p", "w")).rejects.toBeInstanceOf(ConfigError);
    expect(fetchImpl).not.toHaveBeenCalled();
  });

  it("accepts https and sends the bearer token only to the configured origin", async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce(json(200, { accessToken: "a", refreshToken: "r" }))
      .mockResolvedValueOnce(json(200, { user: {} }));
    const client = new ApiClient({ baseUrl: "https://api.example.com/api/v1", requireHttps: true, fetchImpl });
    await client.login("p", "w");
    await client.me();
    for (const [url] of fetchImpl.mock.calls) expect(String(url).startsWith("https://api.example.com/")).toBe(true);
  });
});

describe("HTTP security headers", () => {
  it("forbids framing, sniffing and unknown script/connect origins", async () => {
    const modulePath = "../../../next.config.mjs";
    const { default: config } = (await import(/* @vite-ignore */ modulePath)) as {
      default: { headers: () => Promise<{ headers: { key: string; value: string }[] }[]>; poweredByHeader: boolean };
    };
    const [{ headers }] = await config.headers();
    const byKey = Object.fromEntries(headers.map((h) => [h.key, h.value]));
    expect(byKey["Content-Security-Policy"]).toContain("frame-ancestors 'none'");
    expect(byKey["Content-Security-Policy"]).toContain("object-src 'none'");
    expect(byKey["Content-Security-Policy"]).toContain("default-src 'self'");
    expect(byKey["X-Content-Type-Options"]).toBe("nosniff");
    expect(byKey["X-Frame-Options"]).toBe("DENY");
    expect(byKey["Referrer-Policy"]).toBe("no-referrer");
    expect(config.poweredByHeader).toBe(false);
  });
});
