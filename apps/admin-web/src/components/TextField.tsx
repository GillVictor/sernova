"use client";

import { useId, type InputHTMLAttributes } from "react";
import { FieldHelp } from "./FieldHelp";
import { fieldTexts, type FieldName, type FormName } from "./fieldTexts";

type TextFieldProps<F extends FormName> = Omit<
  InputHTMLAttributes<HTMLInputElement>,
  "id" | "name" | "placeholder"
> & {
  /** Form whose texts live under `<form>.fields.<name>` in fr.json. */
  form: F;
  name: FieldName<F>;
  error?: string;
};

/**
 * Every text/number/password input goes through this component (or SelectField,
 * CheckboxField), so a help tooltip with texts from fr.json is always present.
 */
export function TextField<F extends FormName>({ form, name, error, ...input }: TextFieldProps<F>) {
  const id = useId();
  const { label, placeholder, help } = fieldTexts(form, name);
  const errorId = `${id}-error`;

  return (
    <div className="field">
      <div className="field__head">
        <label htmlFor={id}>{label}</label>
        <FieldHelp fieldLabel={label} text={help} />
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
