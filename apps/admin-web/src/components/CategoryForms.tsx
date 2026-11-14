"use client";

import { useState, type FormEvent } from "react";
import { CheckboxField } from "./CheckboxField";
import { SelectField } from "./SelectField";
import { TextField } from "./TextField";
import { messages, t } from "@/i18n";
import { ApiError } from "@/lib/api/errors";
import { errorMessage } from "@/lib/api/messages";
import type {
  AddAttributeInput,
  Category,
  CreateCategoryInput,
  Family,
  UpdateCategoryInput,
  ValueType,
  VerificationLevel,
} from "@/lib/api/client";

const FAMILIES = Object.keys(messages.category.options.family) as Family[];
const LEVELS = Object.keys(messages.category.options.level) as VerificationLevel[];
const VALUE_TYPES = Object.keys(messages.attribute.options.valueType) as ValueType[];

const familyOptions = FAMILIES.map((v) => ({ value: v, label: t(`category.options.family.${v}`) }));
const levelOptions = LEVELS.map((v) => ({ value: v, label: t(`category.options.level.${v}`) }));
const typeOptions = VALUE_TYPES.map((v) => ({ value: v, label: t(`attribute.options.valueType.${v}`) }));

type Errors = Record<string, string | undefined>;

/** Server-side validation errors[] → one message per field (stable codes only). */
function serverFieldErrors(e: unknown): Errors {
  if (!(e instanceof ApiError)) return {};
  return Object.fromEntries(
    e.fieldErrors.map((fe) => [fe.field, fe.code === "REQUIRED" ? t("validation.required") : t("validation.invalid")]),
  );
}

export function flatten(tree: Category[], depth = 0): { category: Category; depth: number }[] {
  return tree.flatMap((c) => [{ category: c, depth }, ...flatten(c.children ?? [], depth + 1)]);
}

export function CreateCategoryForm({
  tree,
  onCreate,
}: {
  tree: Category[];
  onCreate: (input: CreateCategoryInput) => Promise<void>;
}) {
  const [name, setName] = useState("");
  const [parentId, setParentId] = useState("");
  const [order, setOrder] = useState("0");
  const [family, setFamily] = useState<Family>("Numerique");
  const [level, setLevel] = useState<VerificationLevel>("N0");
  const [errors, setErrors] = useState<Errors>({});
  const [formError, setFormError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const parents = [
    { value: "", label: t("category.rootOption") },
    ...flatten(tree).map(({ category, depth }) => ({
      value: category.id,
      label: `${"— ".repeat(depth)}${category.name}`,
    })),
  ];

  async function submit(event: FormEvent) {
    event.preventDefault();
    const next: Errors = {};
    if (!name.trim()) next.name = t("validation.required");
    else if (name.trim().length > 80) next.name = t("validation.nameTooLong", { max: 80 });
    if (!/^-?\d+$/.test(order.trim())) next.order = t("validation.orderInteger");
    setErrors(next);
    setFormError(null);
    if (Object.keys(next).length) return;

    setBusy(true);
    try {
      await onCreate({
        ...(parentId ? { parentId } : { family }), // family is inherited from the parent otherwise
        name: name.trim(),
        order: Number(order),
        minVerificationLevel: level,
      });
      setName("");
      setOrder("0");
    } catch (e) {
      setErrors(serverFieldErrors(e));
      setFormError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit} noValidate aria-label={t("category.createTitle")}>
      <h2>{t("category.createTitle")}</h2>
      <TextField form="category" name="name" value={name} maxLength={80} onChange={(e) => setName(e.target.value)} error={errors.name} />
      <SelectField form="category" name="parent" value={parentId} onChange={(e) => setParentId(e.target.value)} options={parents} />
      {!parentId && (
        <SelectField form="category" name="family" value={family} onChange={(e) => setFamily(e.target.value as Family)} options={familyOptions} error={errors.family} />
      )}
      <TextField form="category" name="order" type="number" inputMode="numeric" value={order} onChange={(e) => setOrder(e.target.value)} error={errors.order} />
      <SelectField form="category" name="minVerificationLevel" value={level} onChange={(e) => setLevel(e.target.value as VerificationLevel)} options={levelOptions} />
      {formError && <p className="field__error" role="alert">{formError}</p>}
      <button type="submit" disabled={busy}>{busy ? t("category.creating") : t("category.createSubmit")}</button>
    </form>
  );
}

export function EditCategoryForm({
  category,
  onSave,
}: {
  category: Category;
  onSave: (id: string, input: UpdateCategoryInput) => Promise<void>;
}) {
  const [name, setName] = useState(category.name);
  const [order, setOrder] = useState(String(category.order));
  const [active, setActive] = useState(category.active);
  const [level, setLevel] = useState<VerificationLevel>(category.minVerificationLevel);
  const [errors, setErrors] = useState<Errors>({});
  const [formError, setFormError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    const next: Errors = {};
    if (!name.trim()) next.name = t("validation.required");
    else if (name.trim().length > 80) next.name = t("validation.nameTooLong", { max: 80 });
    if (!/^-?\d+$/.test(order.trim())) next.order = t("validation.orderInteger");
    setErrors(next);
    setFormError(null);
    if (Object.keys(next).length) return;

    // Send only what changed (PATCH).
    const changes: UpdateCategoryInput = {};
    if (name.trim() !== category.name) changes.name = name.trim();
    if (Number(order) !== category.order) changes.order = Number(order);
    if (active !== category.active) changes.active = active;
    if (level !== category.minVerificationLevel) changes.minVerificationLevel = level;
    if (!Object.keys(changes).length) return;

    setBusy(true);
    try {
      await onSave(category.id, changes);
    } catch (e) {
      setErrors(serverFieldErrors(e));
      setFormError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit} noValidate aria-label={t("category.editTitle", { name: category.name })}>
      <h2>{t("category.editTitle", { name: category.name })}</h2>
      <TextField form="category" name="name" value={name} maxLength={80} onChange={(e) => setName(e.target.value)} error={errors.name} />
      <TextField form="category" name="order" type="number" inputMode="numeric" value={order} onChange={(e) => setOrder(e.target.value)} error={errors.order} />
      <SelectField form="category" name="minVerificationLevel" value={level} onChange={(e) => setLevel(e.target.value as VerificationLevel)} options={levelOptions} />
      <CheckboxField form="category" name="active" checked={active} onChange={(e) => setActive(e.target.checked)} />
      {formError && <p className="field__error" role="alert">{formError}</p>}
      <button type="submit" disabled={busy}>{busy ? t("category.saving") : t("category.saveSubmit")}</button>
    </form>
  );
}

export function AddAttributeForm({ onAdd }: { onAdd: (input: AddAttributeInput) => Promise<void> }) {
  const [name, setName] = useState("");
  const [valueType, setValueType] = useState<ValueType>("Texte");
  const [required, setRequired] = useState(false);
  const [options, setOptions] = useState("");
  const [errors, setErrors] = useState<Errors>({});
  const [formError, setFormError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    const next: Errors = {};
    if (!name.trim()) next.name = t("validation.required");
    else if (name.trim().length > 60) next.name = t("validation.nameTooLong", { max: 60 });
    if (valueType === "Liste" && !options.trim()) next.options = t("validation.optionsRequired");
    else if (options.length > 500) next.options = t("validation.nameTooLong", { max: 500 });
    setErrors(next);
    setFormError(null);
    if (Object.keys(next).length) return;

    setBusy(true);
    try {
      await onAdd({
        name: name.trim(),
        valueType,
        required,
        ...(valueType === "Liste" ? { options: options.trim() } : {}),
      });
      setName("");
      setOptions("");
      setRequired(false);
    } catch (e) {
      setErrors(serverFieldErrors(e));
      setFormError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit} noValidate aria-label={t("attribute.addTitle")}>
      <h3>{t("attribute.addTitle")}</h3>
      <TextField form="attribute" name="name" value={name} maxLength={60} onChange={(e) => setName(e.target.value)} error={errors.name} />
      <SelectField form="attribute" name="valueType" value={valueType} onChange={(e) => setValueType(e.target.value as ValueType)} options={typeOptions} />
      {valueType === "Liste" && (
        <TextField form="attribute" name="options" value={options} maxLength={500} onChange={(e) => setOptions(e.target.value)} error={errors.options} />
      )}
      <CheckboxField form="attribute" name="required" checked={required} onChange={(e) => setRequired(e.target.checked)} />
      {formError && <p className="field__error" role="alert">{formError}</p>}
      <button type="submit" disabled={busy}>{busy ? t("attribute.adding") : t("attribute.addSubmit")}</button>
    </form>
  );
}
