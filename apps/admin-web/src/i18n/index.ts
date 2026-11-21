import fr from "./fr.json";

type Messages = typeof fr;

/** Dotted paths to string leaves, e.g. "login.fields.phone.help". */
type Leaves<T, P extends string = ""> = {
  [K in keyof T & string]: T[K] extends string
    ? `${P}${K}`
    : Leaves<T[K], `${P}${K}.`>;
}[keyof T & string];

export type MessageKey = Leaves<Messages>;

const messages: Messages = fr;

/** Returns the French text for a key, replacing {placeholders}. */
export function t(key: MessageKey, params: Record<string, string | number> = {}): string {
  const value = key
    .split(".")
    .reduce<unknown>((node, part) => (node as Record<string, unknown>)?.[part], messages);
  if (typeof value !== "string") return key;
  return value.replace(/\{(\w+)\}/g, (_, name) => String(params[name] ?? `{${name}}`));
}

export { messages };
