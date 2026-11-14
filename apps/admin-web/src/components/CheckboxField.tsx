"use client";

import { useId, type InputHTMLAttributes } from "react";
import { FieldHelp } from "./FieldHelp";
import { fieldTexts, type FieldName, type FormName } from "./fieldTexts";

type CheckboxFieldProps<F extends FormName> = Omit<
  InputHTMLAttributes<HTMLInputElement>,
  "id" | "name" | "type"
> & {
  form: F;
  name: FieldName<F>;
};

export function CheckboxField<F extends FormName>({ form, name, ...input }: CheckboxFieldProps<F>) {
  const id = useId();
  const { label, help } = fieldTexts(form, name);

  return (
    <div className="field field--checkbox">
      <div className="field__head">
        <input {...input} id={id} name={name} type="checkbox" />
        <label htmlFor={id}>{label}</label>
        <FieldHelp fieldLabel={label} text={help} />
      </div>
    </div>
  );
}
