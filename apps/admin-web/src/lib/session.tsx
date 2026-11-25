"use client";

import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { ApiClient, apiBaseUrl, type CurrentUser } from "@/lib/api/client";
import { errorMessage } from "@/lib/api/messages";

interface Session {
  client: ApiClient;
  /** True once a login succeeded (tokens live in memory only). */
  authenticated: boolean;
  setAuthenticated: (value: boolean) => void;
  /** EP-009 answer, loaded once per login (D33); null until loaded. */
  me: CurrentUser | null;
  setMe: (value: CurrentUser | null) => void;
}

const SessionContext = createContext<Session | null>(null);

export function SessionProvider({ children }: { children: ReactNode }) {
  const [authenticated, setAuthenticated] = useState(false);
  const [me, setMe] = useState<CurrentUser | null>(null);
  const client = useMemo(
    () => new ApiClient({ baseUrl: apiBaseUrl, onSessionLost: () => setAuthenticated(false) }),
    [],
  );
  // Never keep the previous user's rights after a logout or a lost session.
  useEffect(() => {
    if (!authenticated) setMe(null);
  }, [authenticated]);
  const value = useMemo(
    () => ({ client, authenticated, setAuthenticated, me, setMe }),
    [client, authenticated, me],
  );
  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

export function useSession(): Session {
  const ctx = useContext(SessionContext);
  if (!ctx) throw new Error("useSession must be used inside SessionProvider");
  return ctx;
}

/** Loads EP-009 once after login and shares it (name, permissions) between screens. */
export function useCurrentUser(): { me: CurrentUser | null; error: string | null } {
  const { client, authenticated, me, setMe } = useSession();
  const [error, setError] = useState<string | null>(null);
  useEffect(() => {
    if (!authenticated || me) return;
    client
      .me()
      .then((value) => {
        setMe(value);
        setError(null);
      })
      .catch((e) => setError(errorMessage(e)));
  }, [authenticated, client, me, setMe]);
  return { me, error };
}
