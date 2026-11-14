import { readdirSync, readFileSync, statSync } from "node:fs";
import path from "node:path";
import { describe, expect, it } from "vitest";
import { messages, t } from "./index";

const srcDir = path.resolve(__dirname, "..");

function files(dir: string): string[] {
  return readdirSync(dir).flatMap((f) => {
    const p = path.join(dir, f);
    return statSync(p).isDirectory() ? files(p) : [p];
  });
}

describe("French resources", () => {
  it("every field has a non-empty label and help text", () => {
    for (const [name, field] of Object.entries(messages.login.fields)) {
      expect(field.label, `${name}.label`).not.toBe("");
      expect(field.help.length, `${name}.help`).toBeGreaterThan(20);
    }
  });

  it("no raw <input> is used outside TextField (so no field escapes its tooltip)", () => {
    const offenders = files(srcDir)
      .filter((f) => /\.tsx$/.test(f) && !/\.test\.tsx$/.test(f) && !f.endsWith("TextField.tsx"))
      .filter((f) => /<input[\s>]/.test(readFileSync(f, "utf8")));
    expect(offenders).toEqual([]);
  });

  it("interpolates placeholders", () => {
    expect(t("home.welcome", { name: "Ada" })).toBe("Connecté en tant que Ada.");
  });
});
