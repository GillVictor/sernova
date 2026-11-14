"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { t } from "@/i18n";
import { errorMessage } from "@/lib/api/messages";
import { useSession } from "@/lib/session";

export default function HomePage() {
  const { client, authenticated, setAuthenticated } = useSession();
  const router = useRouter();
  const [name, setName] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!authenticated) {
      router.replace("/login");
      return;
    }
    client
      .me()
      .then((me) => setName(me.user.displayName ?? ""))
      .catch((e) => setError(errorMessage(e)));
  }, [authenticated, client, router]);

  async function logout() {
    await client.logout().catch(() => undefined);
    setAuthenticated(false);
  }

  if (!authenticated) return null;

  return (
    <main className="card">
      <h1>{t("home.title")}</h1>
      {error && <p className="field__error" role="alert">{error}</p>}
      {name !== null && <p>{t("home.welcome", { name })}</p>}
      <button type="button" onClick={logout}>{t("home.logout")}</button>
    </main>
  );
}
