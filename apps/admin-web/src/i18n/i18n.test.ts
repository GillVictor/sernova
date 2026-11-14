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
  it("every field of every form has a non-empty label and help text", () => {
    const forms = { login: messages.login.fields, category: messages.category.fields, attribute: messages.attribute.fields };
    for (const [form, fields] of Object.entries(forms)) {
      for (const [name, field] of Object.entries(fields)) {
        expect(field.label, `${form}.${name}.label`).not.toBe("");
        expect(field.help.length, `${form}.${name}.help`).toBeGreaterThan(20);
      }
    }
  });

  it("every enum value shown in a list has a French label", () => {
    expect(Object.keys(messages.category.options.family)).toEqual(["Numerique", "Domicile", "Travaux", "Vente", "Livraison"]);
    expect(Object.keys(messages.category.options.level)).toEqual(["N0", "N1", "N2", "N3"]);
    expect(Object.keys(messages.attribute.options.valueType)).toEqual(["Texte", "Nombre", "Booleen", "Liste"]);
  });

  it("no raw <input>/<select>/<textarea> outside the field components (no field escapes its tooltip)", () => {
    const allowed = ["TextField.tsx", "SelectField.tsx", "CheckboxField.tsx"];
    const offenders = files(srcDir)
      .filter((f) => /\.tsx$/.test(f) && !/\.test\.tsx$/.test(f) && !allowed.some((a) => f.endsWith(a)))
      .filter((f) => /<(input|select|textarea)[\s>]/.test(readFileSync(f, "utf8")));
    expect(offenders).toEqual([]);
  });

  it("interpolates placeholders", () => {
    expect(t("home.welcome", { name: "Ada" })).toBe("Connecté en tant que Ada.");
  });
});
