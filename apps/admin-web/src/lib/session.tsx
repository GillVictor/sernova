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

interface SessionProviderProps {
  children: ReactNode;
  /** Tests only: a ready-made client and an already open session. */
  client?: ApiClient;
  initialAuthenticated?: boolean;
}

export function SessionProvider({ children, client: injected, initialAuthenticated = false }: SessionProviderProps) {
  const [authenticated, setAuthenticated] = useState(initialAuthenticated);
  const client = useMemo(
    () => injected ?? new ApiClient({ baseUrl: apiBaseUrl, onSessionLost: () => setAuthenticated(false) }),
    [injected],
  );
  const value = useMemo(() => ({ client, authenticated, setAuthenticated }), [client, authenticated]);
  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

export function useSession(): Session {
  const ctx = useContext(SessionContext);
  if (!ctx) throw new Error("useSession must be used inside SessionProvider");
  return ctx;
}
