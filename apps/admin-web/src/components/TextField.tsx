"use client";

import { useId, type InputHTMLAttributes } from "react";
import { t, type MessageKey } from "@/i18n";
import { FieldHelp } from "./FieldHelp";

type FieldName = "phone" | "password";

interface TextFieldProps
  extends Omit<InputHTMLAttributes<HTMLInputElement>, "id" | "name" | "placeholder"> {
  /** Key under `login.fields` (label, placeholder, help) in src/i18n/fr.json. */
  name: FieldName;
  /** Message key prefix of the form, e.g. "login.fields". */
  scope?: "login.fields";
  error?: string;
}

/**
 * Every text input of the app goes through this component, so that a help
 * tooltip (texts in fr.json) is always present: there is no way to omit it.
 */
export function TextField({ name, scope = "login.fields", error, ...input }: TextFieldProps) {
  const id = useId();
  const key = (part: "label" | "placeholder" | "help") => `${scope}.${name}.${part}` as MessageKey;
  const label = t(key("label"));
  const placeholder = t(key("placeholder"));
  const errorId = `${id}-error`;

  return (
    <div className="field">
      <div className="field__head">
        <label htmlFor={id}>{label}</label>
        <FieldHelp fieldLabel={label} text={t(key("help"))} />
      </div>
      <input
        {...input}
        id={id}
        name={name}
        placeholder={placeholder || undefined}
        aria-invalid={error ? true : undefined}
        aria-describedby={error ? errorId : undefined}
      />
      {error && (
        <p id={errorId} className="field__error" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}
