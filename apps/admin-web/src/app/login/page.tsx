"use client";

import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { TextField } from "@/components/TextField";
import { t } from "@/i18n";
import { errorMessage } from "@/lib/api/messages";
import { useSession } from "@/lib/session";

export default function LoginPage() {
  const { client, setAuthenticated } = useSession();
  const router = useRouter();
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [fieldErrors, setFieldErrors] = useState<{ phone?: string; password?: string }>({});
  const [formError, setFormError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    const errors = {
      phone: phone.trim() ? undefined : t("validation.required"),
      password: password ? undefined : t("validation.required"),
    };
    setFieldErrors(errors);
    setFormError(null);
    if (errors.phone || errors.password) return;

    setSubmitting(true);
    try {
      await client.login(phone.trim(), password);
      setAuthenticated(true);
      router.replace("/");
    } catch (e) {
      setFormError(errorMessage(e));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <main className="card">
      <h1>{t("login.title")}</h1>
      <form onSubmit={onSubmit} noValidate>
        <TextField
          form="login"
          name="phone"
          type="tel"
          autoComplete="username"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          error={fieldErrors.phone}
        />
        <TextField
          form="login"
          name="password"
          type="password"
          autoComplete="current-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          error={fieldErrors.password}
        />
        {formError && <p className="field__error" role="alert">{formError}</p>}
        <button type="submit" disabled={submitting}>
          {submitting ? t("login.submitting") : t("login.submit")}
        </button>
      </form>
    </main>
  );
}
