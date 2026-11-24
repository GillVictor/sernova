"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { t } from "@/i18n";
import { CATEGORIES_MANAGE, hasPermission } from "@/lib/permissions";
import { useCurrentUser, useSession } from "@/lib/session";

export default function HomePage() {
  const { client, authenticated, setAuthenticated } = useSession();
  const router = useRouter();
  const { me, error } = useCurrentUser();

  useEffect(() => {
    if (!authenticated) {
      router.replace("/login");
      return;
    }
  }, [authenticated, router]);

  async function logout() {
    await client.logout().catch(() => undefined);
    setAuthenticated(false);
  }

  if (!authenticated) return null;

  return (
    <main className="card">
      <h1>{t("home.title")}</h1>
      {error && <p className="field__error" role="alert">{error}</p>}
      {me && <p>{t("home.welcome", { name: me.user.displayName ?? "" })}</p>}
      {hasPermission(me?.permissions, CATEGORIES_MANAGE) && (
        <p><Link href="/categories">{t("home.categories")}</Link></p>
      )}
      <button type="button" onClick={logout}>{t("home.logout")}</button>
    </main>
  );
}
