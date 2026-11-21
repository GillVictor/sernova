"use client";

import { createContext, useContext, useMemo, useState, type ReactNode } from "react";
import { ApiClient, apiBaseUrl } from "@/lib/api/client";

interface Session {
  client: ApiClient;
  /** True once a login succeeded (tokens live in memory only). */
  authenticated: boolean;
  setAuthenticated: (value: boolean) => void;
}

const SessionContext = createContext<Session | null>(null);

export function SessionProvider({ children }: { children: ReactNode }) {
  const [authenticated, setAuthenticated] = useState(false);
  const client = useMemo(
    () => new ApiClient({ baseUrl: apiBaseUrl, onSessionLost: () => setAuthenticated(false) }),
    [],
  );
  const value = useMemo(() => ({ client, authenticated, setAuthenticated }), [client, authenticated]);
  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

export function useSession(): Session {
  const ctx = useContext(SessionContext);
  if (!ctx) throw new Error("useSession must be used inside SessionProvider");
  return ctx;
}
