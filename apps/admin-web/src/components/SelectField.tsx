"use client";

import { useId, type SelectHTMLAttributes } from "react";
import { FieldHelp } from "./FieldHelp";
import { fieldTexts, type FieldName, type FormName } from "./fieldTexts";

type SelectFieldProps<F extends FormName> = Omit<
  SelectHTMLAttributes<HTMLSelectElement>,
  "id" | "name" | "children"
> & {
  form: F;
  name: FieldName<F>;
  options: { value: string; label: string }[];
  error?: string;
};

export function SelectField<F extends FormName>({ form, name, options, error, ...select }: SelectFieldProps<F>) {
  const id = useId();
  const { label, help } = fieldTexts(form, name);
  const errorId = `${id}-error`;

  return (
    <div className="field">
      <div className="field__head">
        <label htmlFor={id}>{label}</label>
        <FieldHelp fieldLabel={label} text={help} />
      </div>
      <select
        {...select}
        id={id}
        name={name}
        aria-invalid={error ? true : undefined}
        aria-describedby={error ? errorId : undefined}
      >
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
      {error && (
        <p id={errorId} className="field__error" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}
