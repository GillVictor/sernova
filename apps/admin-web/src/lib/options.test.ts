import { describe, expect, it } from "vitest";
import { normalizeOptions } from "./options";

describe("normalizeOptions (D34: comma-separated text, 500 characters max)", () => {
  it("trims each value and joins with a comma and a space", () => {
    expect(normalizeOptions("  Neuf ,Occasion,  Reconditionné ")).toEqual({ ok: true, value: "Neuf, Occasion, Reconditionné" });
  });

  it("accepts a single value", () => {
    expect(normalizeOptions("Neuf")).toEqual({ ok: true, value: "Neuf" });
  });

  it("refuses an empty text", () => {
    expect(normalizeOptions("")).toEqual({ ok: false, error: "empty" });
    expect(normalizeOptions("  ,  ")).toMatchObject({ ok: false });
  });

  it("refuses an empty value between or after commas", () => {
    expect(normalizeOptions("a,,b")).toEqual({ ok: false, error: "emptyItem" });
    expect(normalizeOptions("a, b,")).toEqual({ ok: false, error: "emptyItem" });
    expect(normalizeOptions(", a")).toEqual({ ok: false, error: "emptyItem" });
  });

  it("refuses duplicates, ignoring case and spaces, and names the value", () => {
    expect(normalizeOptions("Neuf, Occasion, neuf ")).toEqual({ ok: false, error: "duplicate", value: "neuf" });
  });

  it("refuses a result longer than 500 characters", () => {
    const long = Array.from({ length: 60 }, (_, i) => `valeur-${i}`).join(",");
    expect(normalizeOptions(long)).toEqual({ ok: false, error: "tooLong" });
  });
});
