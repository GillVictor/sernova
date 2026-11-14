// Validates lib/l10n/app_fr.arb without Flutter (run: node tool/check_l10n.mjs).
// Rules: valid JSON; keys are Dart identifiers; every placeholder used is declared
// (and vice versa); every input field has Label + Hint + Help with a real help text.
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const file = path.join(path.dirname(fileURLToPath(import.meta.url)), "../lib/l10n/app_fr.arb");
const arb = JSON.parse(readFileSync(file, "utf8"));
const problems = [];

const messages = Object.entries(arb).filter(([k]) => !k.startsWith("@"));
for (const [key, value] of messages) {
  if (!/^[a-z][A-Za-z0-9]*$/.test(key)) problems.push(`${key}: not a lowerCamelCase Dart identifier`);
  if (typeof value !== "string") { problems.push(`${key}: value must be a string`); continue; }
  const used = new Set([...value.matchAll(/\{(\w+)\}/g)].map((m) => m[1]));
  const declared = new Set(Object.keys(arb["@" + key]?.placeholders ?? {}));
  for (const p of used) if (!declared.has(p)) problems.push(`${key}: placeholder {${p}} not declared`);
  for (const p of declared) if (!used.has(p)) problems.push(`${key}: placeholder ${p} declared but unused`);
  if (!arb["@" + key]?.description) problems.push(`${key}: missing @description`);
}
for (const k of Object.keys(arb)) {
  if (k.startsWith("@") && !k.startsWith("@@") && !(k.slice(1) in arb)) problems.push(`${k}: metadata without message`);
}

// Every "<prefix>Help" must come with "<prefix>Label" and "<prefix>Hint", and vice versa.
const prefixes = new Set(messages.map(([k]) => k.match(/^(.*)(Label|Hint|Help)$/)?.[1]).filter(Boolean));
for (const p of prefixes) {
  for (const part of ["Label", "Hint", "Help"]) if (!(p + part in arb)) problems.push(`${p}${part}: missing (every field needs label, hint and help)`);
  if ((arb[p + "Label"] ?? "") === "") problems.push(`${p}Label: empty`);
  if ((arb[p + "Help"] ?? "").length < 20) problems.push(`${p}Help: help text missing or too short`);
}

if (problems.length) {
  console.error(problems.join("\n"));
  process.exit(1);
}
console.log(`OK: ${messages.length} messages, ${prefixes.size} fields with help`);
