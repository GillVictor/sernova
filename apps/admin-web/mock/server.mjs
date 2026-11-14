// Mock ServNova API for local development (no dependency).
// Implements only the contract routes used by apps/admin-web:
// EP-004 login, EP-005 refresh, EP-006 logout, EP-009 users/me.
// Dev credentials are fake and local to this file.
import { createServer } from "node:http";
import { randomUUID } from "node:crypto";

const PORT = Number(process.env.PORT ?? 4010);
const BASE = "/api/v1";
const DEV_PHONE = "+242060000000";
const DEV_PASSWORD = "dev-only-password";

const accessTokens = new Set();
const refreshTokens = new Set();
let attempts = 0;

function problem(res, status, code, extra = {}, headers = {}) {
  res.writeHead(status, { "Content-Type": "application/problem+json", ...headers });
  res.end(JSON.stringify({ status, code, title: code, traceId: randomUUID(), ...extra }));
}

function json(res, status, body) {
  res.writeHead(status, { "Content-Type": "application/json" });
  res.end(JSON.stringify(body));
}

function issue() {
  const pair = { accessToken: randomUUID(), refreshToken: randomUUID() };
  accessTokens.add(pair.accessToken);
  refreshTokens.add(pair.refreshToken);
  return pair;
}

async function readBody(req) {
  const chunks = [];
  for await (const c of req) chunks.push(c);
  try { return JSON.parse(Buffer.concat(chunks).toString() || "{}"); } catch { return {}; }
}

createServer(async (req, res) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, Accept-Language");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  if (req.method === "OPTIONS") { res.writeHead(204); return res.end(); }

  const path = (req.url ?? "").split("?")[0];
  const route = `${req.method} ${path}`;

  if (route === `POST ${BASE}/auth/login`) {
    const { phone, password } = await readBody(req);
    if (!phone || !password) {
      return problem(res, 422, "VALIDATION_FAILED", {
        errors: [!phone && { field: "phone", code: "REQUIRED" }, !password && { field: "password", code: "REQUIRED" }].filter(Boolean),
      });
    }
    if (++attempts > 5) return problem(res, 429, "RATE_LIMITED", {}, { "Retry-After": "30" });
    if (phone !== DEV_PHONE || password !== DEV_PASSWORD) return problem(res, 401, "INVALID_CREDENTIALS");
    attempts = 0;
    return json(res, 200, issue());
  }

  if (route === `POST ${BASE}/auth/refresh`) {
    const { refreshToken } = await readBody(req);
    if (!refreshTokens.delete(refreshToken)) return problem(res, 401, "TOKEN_REVOKED");
    return json(res, 200, issue());
  }

  if (route === `POST ${BASE}/auth/logout`) {
    if (!accessTokens.has((req.headers.authorization ?? "").replace("Bearer ", ""))) return problem(res, 401, "UNAUTHENTICATED");
    const { refreshToken } = await readBody(req);
    refreshTokens.delete(refreshToken);
    res.writeHead(204);
    return res.end();
  }

  if (route === `GET ${BASE}/users/me`) {
    if (!accessTokens.has((req.headers.authorization ?? "").replace("Bearer ", ""))) return problem(res, 401, "UNAUTHENTICATED");
    return json(res, 200, { user: { displayName: "Admin de démonstration" }, capacities: ["Client"], providerStatus: null });
  }

  return problem(res, 404, "NOT_FOUND");
}).listen(PORT, () => console.log(`Mock API on http://localhost:${PORT}${BASE} (phone ${DEV_PHONE})`));
