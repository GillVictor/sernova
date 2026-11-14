import { messages, t, type MessageKey } from "@/i18n";

type Forms = {
  login: typeof messages.login.fields;
  category: typeof messages.category.fields;
  attribute: typeof messages.attribute.fields;
};

export type FormName = keyof Forms;
export type FieldName<F extends FormName> = keyof Forms[F] & string;

/** Label, example and help text of a field, from src/i18n/fr.json. */
export function fieldTexts<F extends FormName>(form: F, name: FieldName<F>) {
  const key = (part: "label" | "placeholder" | "help") => `${form}.fields.${name}.${part}` as MessageKey;
  return { label: t(key("label")), placeholder: t(key("placeholder")), help: t(key("help")) };
}
