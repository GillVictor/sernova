// Mock ServNova API for local development (no dependency).
// Implements only the contract routes used by apps/admin-web:
// EP-004 login, EP-005 refresh, EP-006 logout, EP-009 users/me,
// EP-021/022 categories and attributes, EP-089/090/091 admin category routes.
// Set MOCK_NO_PERMISSION=1 to make the admin routes answer 403 FORBIDDEN.
// Dev credentials are fake and local to this file.
import { createServer } from "node:http";
import { randomUUID } from "node:crypto";

const PORT = Number(process.env.PORT ?? 4010);
const BASE = "/api/v1";
const DEV_PHONE = "+242060000000";
const DEV_PASSWORD = "dev-only-password";

// In-memory categories (tree built on read). Families come from the data dictionary.
const categories = [];
const attributes = new Map();
function addCategory({ parentId = null, name, order = 0, family, minVerificationLevel = "N0" }) {
  const parent = parentId ? categories.find((c) => c.id === parentId) : null;
  const c = { id: randomUUID(), parentId, name, order, active: true, family: parent ? parent.family : family, minVerificationLevel };
  categories.push(c);
  return c;
}
const roots = Object.fromEntries(
  [["Numerique", "Services numériques"], ["Domicile", "Services à domicile"], ["Travaux", "Travaux"], ["Vente", "Vente"], ["Livraison", "Livraison"]]
    .map(([family, name], i) => [family, addCategory({ name, order: i, family })]),
);
addCategory({ parentId: roots.Domicile.id, name: "Plomberie", order: 1 });
addCategory({ parentId: roots.Domicile.id, name: "Ménage", order: 2 });
addCategory({ parentId: roots.Vente.id, name: "Téléphones", order: 1 });
function tree(parentId = null) {
  return categories
    .filter((c) => c.parentId === parentId && c.active)
    .sort((a, b) => a.order - b.order)
    .map(({ parentId: _p, ...c }) => ({ ...c, children: tree(c.id) }));
}
const FAMILIES = ["Numerique", "Domicile", "Travaux", "Vente", "Livraison"];
const LEVELS = ["N0", "N1", "N2", "N3"];
const TYPES = ["Texte", "Nombre", "Booleen", "Liste"];

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
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, PATCH, OPTIONS");
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

  // --- Categories (EP-021, EP-022: public) ---
  if (route === `GET ${BASE}/categories`) return json(res, 200, tree());
  let m = path.match(new RegExp(`^${BASE}/categories/([^/]+)/attributes$`));
  if (m && req.method === "GET") {
    if (!categories.some((c) => c.id === m[1])) return problem(res, 404, "NOT_FOUND");
    return json(res, 200, attributes.get(m[1]) ?? []);
  }

  // --- Admin category routes (EP-089, EP-090, EP-091) ---
  const adminMatch = path.startsWith(`${BASE}/admin/categories`);
  if (adminMatch) {
    if (!accessTokens.has((req.headers.authorization ?? "").replace("Bearer ", ""))) return problem(res, 401, "UNAUTHENTICATED");
    if (process.env.MOCK_NO_PERMISSION === "1") return problem(res, 403, "FORBIDDEN");
    const fieldErrors = (list) => list.filter(Boolean).map(([field, code]) => ({ field, code }));
    const invalid = (list) => problem(res, 422, "VALIDATION_FAILED", { errors: fieldErrors(list) });

    if (route === `POST ${BASE}/admin/categories`) {
      const b = await readBody(req);
      const bad = [
        !b.name || typeof b.name !== "string" || b.name.length > 80 ? ["name", b.name ? "INVALID" : "REQUIRED"] : null,
        !Number.isInteger(b.order) ? ["order", "INVALID"] : null,
        !b.parentId && !FAMILIES.includes(b.family) ? ["family", "REQUIRED"] : null,
        !LEVELS.includes(b.minVerificationLevel) ? ["minVerificationLevel", "INVALID"] : null,
        b.parentId && !categories.some((c) => c.id === b.parentId) ? ["parentId", "INVALID"] : null,
      ].filter(Boolean);
      if (bad.length) return invalid(bad);
      if (categories.some((c) => c.parentId === (b.parentId ?? null) && c.name.toLowerCase() === b.name.toLowerCase())) return problem(res, 409, "DUPLICATE_NAME");
      const { parentId: _p, ...created } = addCategory(b);
      return json(res, 201, created);
    }

    m = path.match(new RegExp(`^${BASE}/admin/categories/([^/]+)(/attributes)?$`));
    if (m) {
      const category = categories.find((c) => c.id === m[1]);
      if (!category) return problem(res, 404, "NOT_FOUND");
      const b = await readBody(req);
      if (req.method === "PATCH" && !m[2]) {
        const bad = [
          "name" in b && (!b.name || b.name.length > 80) ? ["name", "INVALID"] : null,
          "order" in b && !Number.isInteger(b.order) ? ["order", "INVALID"] : null,
          "minVerificationLevel" in b && !LEVELS.includes(b.minVerificationLevel) ? ["minVerificationLevel", "INVALID"] : null,
        ].filter(Boolean);
        if (bad.length) return invalid(bad);
        if (b.name && categories.some((c) => c.id !== category.id && c.parentId === category.parentId && c.name.toLowerCase() === b.name.toLowerCase())) return problem(res, 409, "DUPLICATE_NAME");
        if (b.active === false && category.parentId === null) return problem(res, 409, "CATEGORY_IN_USE"); // demo of the 409 case
        for (const k of ["name", "order", "active", "minVerificationLevel"]) if (k in b) category[k] = b[k];
        const { parentId: _p, ...updated } = category;
        return json(res, 200, updated);
      }
      if (req.method === "POST" && m[2]) {
        const bad = [
          !b.name || b.name.length > 60 ? ["name", b.name ? "INVALID" : "REQUIRED"] : null,
          !TYPES.includes(b.valueType) ? ["valueType", "INVALID"] : null,
          typeof b.required !== "boolean" ? ["required", "INVALID"] : null,
          b.valueType === "Liste" && !b.options ? ["options", "REQUIRED"] : null,
        ].filter(Boolean);
        if (bad.length) return invalid(bad);
        const list = attributes.get(category.id) ?? [];
        const def = { id: randomUUID(), name: b.name, valueType: b.valueType, required: b.required, ...(b.options ? { options: b.options } : {}) };
        attributes.set(category.id, [...list, def]);
        return json(res, 201, def);
      }
    }
  }

  return problem(res, 404, "NOT_FOUND");
}).listen(PORT, () => console.log(`Mock API on http://localhost:${PORT}${BASE} (phone ${DEV_PHONE})`));
