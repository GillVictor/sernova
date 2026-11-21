/**
 * Routes consumed by the admin web app. Each entry maps to a line of
 * docs/reference/api-contract.xlsx (sheet "Endpoints"). Do not add a route
 * that is not in the contract: propose it in docs/open-points.md first.
 */
export const routes = {
  /** EP-004 POST /auth/login (Public) */
  login: { id: "EP-004", method: "POST", path: "/auth/login" },
  /** EP-005 POST /auth/refresh (Public) */
  refresh: { id: "EP-005", method: "POST", path: "/auth/refresh" },
  /** EP-006 POST /auth/logout (Authentifié) */
  logout: { id: "EP-006", method: "POST", path: "/auth/logout" },
  /** EP-009 GET /users/me (Authentifié) */
  me: { id: "EP-009", method: "GET", path: "/users/me" },
  /** EP-021 GET /categories (Public) */
  categories: { id: "EP-021", method: "GET", path: "/categories" },
  /** EP-022 GET /categories/{id}/attributes (Public) */
  categoryAttributes: { id: "EP-022", method: "GET", path: "/categories/{id}/attributes" },
  /** EP-089 POST /admin/categories (Admin : categories.manage) */
  createCategory: { id: "EP-089", method: "POST", path: "/admin/categories" },
  /** EP-090 PATCH /admin/categories/{id} (Admin : categories.manage) */
  updateCategory: { id: "EP-090", method: "PATCH", path: "/admin/categories/{id}" },
  /** EP-091 POST /admin/categories/{id}/attributes (Admin : categories.manage) */
  addAttribute: { id: "EP-091", method: "POST", path: "/admin/categories/{id}/attributes" },
} as const;

export type Route = (typeof routes)[keyof typeof routes];
