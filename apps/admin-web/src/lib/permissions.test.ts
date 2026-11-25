import { describe, expect, it } from "vitest";
import { CATEGORIES_MANAGE, hasPermission } from "./permissions";

describe("hasPermission (D33: display only, the server stays the authority)", () => {
  it("is true only when the exact code is listed", () => {
    expect(hasPermission([CATEGORIES_MANAGE, "journal.read"], CATEGORIES_MANAGE)).toBe(true);
    expect(hasPermission(["journal.read"], CATEGORIES_MANAGE)).toBe(false);
  });

  it("denies when the list is missing, empty or not loaded", () => {
    expect(hasPermission(undefined, CATEGORIES_MANAGE)).toBe(false);
    expect(hasPermission(null, CATEGORIES_MANAGE)).toBe(false);
    expect(hasPermission([], CATEGORIES_MANAGE)).toBe(false);
  });

  it("does not match a longer or different code", () => {
    expect(hasPermission(["categories.manage.all"], CATEGORIES_MANAGE)).toBe(false);
    expect(hasPermission(["Categories.Manage"], CATEGORIES_MANAGE)).toBe(false);
  });
});
