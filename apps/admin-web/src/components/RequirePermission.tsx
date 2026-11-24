import type { ReactNode } from "react";
import { t } from "@/i18n";
import { hasPermission } from "@/lib/permissions";

/**
 * Shows its children only when the admin permission is listed (D33).
 * `permissions === null` means "not loaded yet". This is display only:
 * every admin route still answers 403 without the permission.
 */
export function RequirePermission({
  permissions,
  code,
  children,
}: {
  permissions: readonly string[] | null;
  code: string;
  children: ReactNode;
}) {
  if (permissions === null) return <p className="muted">{t("permissions.loading")}</p>;
  if (!hasPermission(permissions, code)) {
    return (
      <p className="field__error" role="alert">
        {t("permissions.denied")}
      </p>
    );
  }
  return <>{children}</>;
}
