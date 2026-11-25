/**
 * Admin permission codes (api-contract.xlsx, sheet "Conventions", row
 * "Permissions admin"). D33: the list comes from EP-009 `permissions[]` and
 * only drives what the screens show; the server stays the authority (403).
 */
export const CATEGORIES_MANAGE = "categories.manage";

/** Fail closed: a missing, empty or not-yet-loaded list grants nothing. */
export function hasPermission(permissions: readonly string[] | null | undefined, code: string): boolean {
  return Array.isArray(permissions) && permissions.includes(code);
}
