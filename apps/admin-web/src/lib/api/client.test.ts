import { describe, expect, it, vi } from "vitest";
import { ApiClient } from "./client";
import { ApiError, NetworkError } from "./errors";
import { errorMessage } from "./messages";

const json = (status: number, body?: unknown, headers: Record<string, string> = {}) =>
  new Response(body === undefined ? null : JSON.stringify(body), { status, headers });

const make = (fetchImpl: typeof fetch, onSessionLost?: () => void) =>
  new ApiClient({ baseUrl: "http://api/api/v1/", fetchImpl, onSessionLost });

describe("ApiClient", () => {
  it("logs in on EP-004 and keeps tokens", async () => {
    const fetchImpl = vi.fn().mockResolvedValue(json(200, { accessToken: "a", refreshToken: "r" }));
    const client = make(fetchImpl);
    await client.login("+242060000000", "pw");
    expect(fetchImpl).toHaveBeenCalledWith(
      "http://api/api/v1/auth/login",
      expect.objectContaining({ method: "POST", body: JSON.stringify({ phone: "+242060000000", password: "pw" }) }),
    );
    expect(client.isAuthenticated).toBe(true);
  });

  it("maps a problem+json error to ApiError with its stable code", async () => {
    const client = make(vi.fn().mockResolvedValue(json(401, { code: "INVALID_CREDENTIALS" })));
    await expect(client.login("x", "y")).rejects.toMatchObject({ status: 401, code: "INVALID_CREDENTIALS" });
    expect(client.isAuthenticated).toBe(false);
  });

  it("exposes Retry-After on 429", async () => {
    const client = make(vi.fn().mockResolvedValue(json(429, { code: "RATE_LIMITED" }, { "Retry-After": "30" })));
    const error = await client.login("x", "y").catch((e) => e);
    expect(error).toBeInstanceOf(ApiError);
    expect(errorMessage(error)).toBe("Trop de tentatives. Réessayez dans 30 secondes.");
  });

  it("refreshes once on TOKEN_EXPIRED then retries (EP-005)", async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce(json(200, { accessToken: "a1", refreshToken: "r1" })) // login
      .mockResolvedValueOnce(json(401, { code: "TOKEN_EXPIRED" })) // me
      .mockResolvedValueOnce(json(200, { accessToken: "a2", refreshToken: "r2" })) // refresh
      .mockResolvedValueOnce(json(200, { user: { displayName: "Ada" } })); // me retry
    const client = make(fetchImpl);
    await client.login("p", "w");
    await expect(client.me()).resolves.toEqual({ user: { displayName: "Ada" } });
    const retryHeaders = (fetchImpl.mock.calls[3][1] as RequestInit).headers as Record<string, string>;
    expect(retryHeaders.Authorization).toBe("Bearer a2");
  });

  it("signals session loss when refresh fails", async () => {
    const lost = vi.fn();
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce(json(200, { accessToken: "a1", refreshToken: "r1" }))
      .mockResolvedValueOnce(json(401, { code: "TOKEN_EXPIRED" }))
      .mockResolvedValueOnce(json(401, { code: "TOKEN_REVOKED" }));
    const client = make(fetchImpl, lost);
    await client.login("p", "w");
    await expect(client.me()).rejects.toBeInstanceOf(ApiError);
    expect(lost).toHaveBeenCalled();
    expect(client.isAuthenticated).toBe(false);
  });

  it("reports network failures", async () => {
    const client = make(vi.fn().mockRejectedValue(new TypeError("fetch failed")));
    const error = await client.login("p", "w").catch((e) => e);
    expect(error).toBeInstanceOf(NetworkError);
    expect(errorMessage(error)).toBe("Impossible de joindre le serveur. Vérifiez votre connexion.");
  });

  it("never shows server-provided text for unknown codes", () => {
    expect(errorMessage(new ApiError(500, "SOMETHING_ELSE"))).toBe("Une erreur est survenue. Réessayez.");
  });
});
