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
    await expect(client.me()).resolves.toEqual({ user: { displayName: "Ada" }, permissions: [] });
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

  it("calls the category routes with path parameters (EP-021, 022, 089, 090, 091)", async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce(json(200, { accessToken: "a", refreshToken: "r" }))
      .mockImplementation(async () => json(200, []));
    const client = make(fetchImpl);
    await client.login("p", "w");

    await client.listCategories();
    await client.categoryAttributes("c 1");
    await client.createCategory({ name: "N", order: 1, family: "Vente", minVerificationLevel: "N0" });
    await client.updateCategory("c1", { active: false });
    await client.addAttribute("c1", { name: "Marque", valueType: "Texte", required: false });

    const calls = fetchImpl.mock.calls.slice(1).map(([url, init]) => `${(init as RequestInit).method} ${url}`);
    expect(calls).toEqual([
      "GET http://api/api/v1/categories",
      "GET http://api/api/v1/categories/c%201/attributes",
      "POST http://api/api/v1/admin/categories",
      "PATCH http://api/api/v1/admin/categories/c1",
      "POST http://api/api/v1/admin/categories/c1/attributes",
    ]);
    const patch = fetchImpl.mock.calls[4][1] as RequestInit;
    expect(patch.body).toBe(JSON.stringify({ active: false }));
    expect((patch.headers as Record<string, string>).Authorization).toBe("Bearer a");
    // public routes send no token
    expect((fetchImpl.mock.calls[1][1] as RequestInit).headers).not.toHaveProperty("Authorization");
  });

  it("keeps field errors of a 422 and the stable code of a 403/409", async () => {
    const client = make(
      vi
        .fn()
        .mockResolvedValueOnce(json(200, { accessToken: "a", refreshToken: "r" })) // login
        .mockResolvedValueOnce(json(422, { code: "VALIDATION_FAILED", errors: [{ field: "name", code: "REQUIRED" }] }))
        .mockResolvedValueOnce(json(403, { code: "FORBIDDEN" }))
        .mockResolvedValueOnce(json(409, { code: "DUPLICATE_NAME" })),
    );
    const input = { name: "", order: 0, family: "Vente" as const, minVerificationLevel: "N0" as const };
    await client.login("p", "w");
    const e1 = await client.createCategory(input).catch((e) => e);
    expect(e1.fieldErrors).toEqual([{ field: "name", code: "REQUIRED" }]);
    expect(errorMessage(await client.createCategory(input).catch((e) => e))).toBe(
      "Vous n'avez pas la permission d'effectuer cette action.",
    );
    expect(errorMessage(await client.createCategory(input).catch((e) => e))).toBe(
      "Ce nom existe déjà dans cette catégorie parente.",
    );
  });
});

describe("ApiClient.me (EP-009, D33)", () => {
  const loggedIn = async (meBody: unknown) => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce(json(200, { accessToken: "a", refreshToken: "r" }))
      .mockResolvedValueOnce(json(200, meBody));
    const client = make(fetchImpl);
    await client.login("+242060000000", "pw");
    return client;
  };

  it("returns permissions[] as a list of codes", async () => {
    const client = await loggedIn({ user: { displayName: "A" }, capacities: ["Client"], providerStatus: null, permissions: ["categories.manage"] });
    expect((await client.me()).permissions).toEqual(["categories.manage"]);
  });

  it("falls back to an empty list when permissions is absent or malformed", async () => {
    for (const permissions of [undefined, null, "categories.manage"]) {
      const client = await loggedIn({ user: {}, permissions });
      expect((await client.me()).permissions).toEqual([]);
    }
  });

  it("keeps only the string codes of a mixed list", async () => {
    const client = await loggedIn({ user: {}, permissions: [1, null, "journal.read"] });
    expect((await client.me()).permissions).toEqual(["journal.read"]);
  });
});
