/** D34 / EP-091: `options` is comma-separated text of 500 characters at most. */
export const OPTIONS_MAX_LENGTH = 500;

export type OptionsResult =
  | { ok: true; value: string }
  | { ok: false; error: "empty" | "emptyItem" | "tooLong" }
  | { ok: false; error: "duplicate"; value: string };

/**
 * Trims each value, refuses empty values and duplicates (ignoring case), and
 * joins the clean values with ", ". The server applies the same rules and stays
 * the authority; this only avoids a useless round trip.
 */
export function normalizeOptions(text: string): OptionsResult {
  if (!text.trim()) return { ok: false, error: "empty" };
  const items = text.split(",").map((item) => item.trim());
  if (items.every((item) => item === "")) return { ok: false, error: "empty" };
  if (items.some((item) => item === "")) return { ok: false, error: "emptyItem" };
  const seen = new Set<string>();
  for (const item of items) {
    const key = item.toLowerCase();
    if (seen.has(key)) return { ok: false, error: "duplicate", value: item };
    seen.add(key);
  }
  const value = items.join(", ");
  if (value.length > OPTIONS_MAX_LENGTH) return { ok: false, error: "tooLong" };
  return { ok: true, value };
}
