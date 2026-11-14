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
} as const;

export type Route = (typeof routes)[keyof typeof routes];
