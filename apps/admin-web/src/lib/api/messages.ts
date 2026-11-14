import { t, type MessageKey } from "@/i18n";
import { ApiError, NetworkError } from "./errors";

const known = new Set([
  "INVALID_CREDENTIALS",
  "ACCOUNT_SUSPENDED",
  "PHONE_NOT_VERIFIED",
  "VALIDATION_FAILED",
  "UNAUTHENTICATED",
  "TOKEN_EXPIRED",
  "TOKEN_REVOKED",
]);

/** Turns an error into a French message. Stable codes only: server texts are never shown. */
export function errorMessage(error: unknown): string {
  if (error instanceof NetworkError) return t("errors.NETWORK");
  if (error instanceof ApiError) {
    if (error.code === "RATE_LIMITED" || error.status === 429) {
      return error.retryAfterSeconds
        ? t("errors.RATE_LIMITED", { seconds: error.retryAfterSeconds })
        : t("errors.RATE_LIMITED_NO_DELAY");
    }
    if (known.has(error.code)) return t(`errors.${error.code}` as MessageKey);
  }
  return t("errors.UNKNOWN");
}
