import { ApiError, ConfigError, NetworkError, type Problem } from "./errors";
import { routes, type Route } from "./routes";

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

export interface CurrentUser {
  user: { displayName?: string } & Record<string, unknown>;
  capacities?: unknown;
  providerStatus?: unknown;
  /** EP-009 (D33): codes of the caller's admin permissions; empty for a non-admin. */
  permissions: string[];
}

/**
 * Shapes below follow the contract's indicative field names (sheet "Endpoints");
 * see OP-17 in docs/open-points.md.
 */
export type Family = "Numerique" | "Domicile" | "Travaux" | "Vente" | "Livraison";
export type VerificationLevel = "N0" | "N1" | "N2" | "N3";
export type ValueType = "Texte" | "Nombre" | "Booleen" | "Liste";

export interface Category {
  id: string;
  name: string;
  order: number;
  active: boolean;
  family: Family;
  minVerificationLevel: VerificationLevel;
  children?: Category[];
}

export interface AttributeDefinition {
  id: string;
  name: string;
  valueType: ValueType;
  required: boolean;
  options?: string;
}

export interface CreateCategoryInput {
  parentId?: string;
  name: string;
  order: number;
  family?: Family;
  minVerificationLevel: VerificationLevel;
}

export interface UpdateCategoryInput {
  name?: string;
  order?: number;
  active?: boolean;
  minVerificationLevel?: VerificationLevel;
}

export interface AddAttributeInput {
  name: string;
  valueType: ValueType;
  required: boolean;
  options?: string;
}

type Fetch = typeof fetch;

export interface ApiClientOptions {
  baseUrl: string;
  /**
   * Refuse to send anything over a non-HTTPS URL (the contract says HTTPS only).
   * Defaults to true in production builds; local development may use http.
   */
  requireHttps?: boolean;
  fetchImpl?: Fetch;
  /** Called when a refresh fails: the session is over. */
  onSessionLost?: () => void;
}

export class ApiClient {
  private tokens: TokenPair | null = null;
  private refreshing: Promise<boolean> | null = null;
  private readonly baseUrl: string;
  private readonly requireHttps: boolean;
  private readonly fetchImpl: Fetch;
  private readonly onSessionLost?: () => void;

  constructor(options: ApiClientOptions) {
    this.baseUrl = options.baseUrl.replace(/\/$/, "");
    this.requireHttps = options.requireHttps ?? process.env.NODE_ENV === "production";
    this.fetchImpl = options.fetchImpl ?? ((...args) => fetch(...args));
    this.onSessionLost = options.onSessionLost;
  }

  get isAuthenticated(): boolean {
    return this.tokens !== null;
  }

  // EP-004
  async login(phone: string, password: string): Promise<void> {
    this.tokens = await this.send<TokenPair>(routes.login, { body: { phone, password } });
  }

  // EP-006 (best effort: the local session is cleared in all cases)
  async logout(): Promise<void> {
    const refreshToken = this.tokens?.refreshToken;
    try {
      if (refreshToken) await this.send<void>(routes.logout, { body: { refreshToken }, auth: true, retry: false });
    } finally {
      this.tokens = null;
    }
  }

  // EP-009
  async me(): Promise<CurrentUser> {
    const body = await this.send<Omit<CurrentUser, "permissions"> & { permissions?: unknown }>(routes.me, { auth: true });
    // Tolerate an absent or malformed list: nothing is granted by default.
    const permissions = Array.isArray(body.permissions) ? body.permissions.filter((p): p is string => typeof p === "string") : [];
    return { ...body, permissions };
  }

  // EP-021
  listCategories(): Promise<Category[]> {
    return this.send<Category[]>(routes.categories);
  }

  // EP-115 (D35): admin tree with inactive categories; EP-021 stays public and active-only
  listAllCategories(): Promise<Category[]> {
    return this.send<Category[]>(routes.allCategories, { auth: true });
  }

  // EP-022
  categoryAttributes(categoryId: string): Promise<AttributeDefinition[]> {
    return this.send<AttributeDefinition[]>(routes.categoryAttributes, { params: { id: categoryId } });
  }

  // EP-089
  createCategory(input: CreateCategoryInput): Promise<Category> {
    return this.send<Category>(routes.createCategory, { body: input, auth: true });
  }

  // EP-090
  updateCategory(id: string, input: UpdateCategoryInput): Promise<Category> {
    return this.send<Category>(routes.updateCategory, { body: input, auth: true, params: { id } });
  }

  // EP-091
  addAttribute(categoryId: string, input: AddAttributeInput): Promise<AttributeDefinition> {
    return this.send<AttributeDefinition>(routes.addAttribute, {
      body: input,
      auth: true,
      params: { id: categoryId },
    });
  }

  private async send<T>(
    route: Route,
    opts: { body?: unknown; auth?: boolean; retry?: boolean; params?: Record<string, string> } = {},
  ): Promise<T> {
    const { body, auth = false, retry = true, params = {} } = opts;
    // Fail closed: never send credentials or tokens over plain HTTP or to an unset URL.
    if (!this.baseUrl || (this.requireHttps && !this.baseUrl.startsWith("https://"))) {
      throw new ConfigError();
    }
    if (auth && !this.tokens) throw new ApiError(401, "UNAUTHENTICATED");
    const path = route.path.replace(/\{(\w+)\}/g, (_, k: string) => encodeURIComponent(params[k] ?? ""));
    const headers: Record<string, string> = { "Accept-Language": "fr" };
    if (body !== undefined) headers["Content-Type"] = "application/json";
    if (auth && this.tokens) headers.Authorization = `Bearer ${this.tokens.accessToken}`;

    let response: Response;
    try {
      response = await this.fetchImpl(`${this.baseUrl}${path}`, {
        method: route.method,
        headers,
        body: body === undefined ? undefined : JSON.stringify(body),
      });
    } catch {
      throw new NetworkError();
    }

    if (response.ok) {
      if (response.status === 204) return undefined as T;
      return (await response.json()) as T;
    }

    const problem = (await response.json().catch(() => ({}))) as Problem;
    const code = problem.code ?? "UNKNOWN";

    if (auth && response.status === 401) {
      if (retry && code === "TOKEN_EXPIRED" && (await this.refresh())) {
        return this.send<T>(route, { ...opts, retry: false });
      }
      // Expired and not renewable, revoked, unknown token, or still 401 after a renewal:
      // the session is over. Drop the tokens so the UI goes back to the login screen.
      this.tokens = null;
      this.onSessionLost?.();
    }

    const retryAfter = Number(response.headers.get("Retry-After"));
    throw new ApiError(
      response.status,
      code,
      problem.errors ?? [],
      Number.isFinite(retryAfter) && retryAfter > 0 ? retryAfter : undefined,
      problem.traceId,
    );
  }

  /** EP-005: rotation of the refresh token. Concurrent callers share one request. */
  private refresh(): Promise<boolean> {
    if (!this.tokens) return Promise.resolve(false);
    this.refreshing ??= this.send<TokenPair>(routes.refresh, {
      body: { refreshToken: this.tokens.refreshToken },
      retry: false,
    })
      .then((pair) => {
        this.tokens = pair;
        return true;
      })
      .catch(() => {
        this.tokens = null;
        return false;
      })
      .finally(() => {
        this.refreshing = null;
      });
    return this.refreshing;
  }
}

/**
 * In development the mock server is the default. In production there is no default:
 * an unset URL makes every request fail closed (ConfigError) instead of falling back to http.
 */
export const apiBaseUrl =
  process.env.NEXT_PUBLIC_API_BASE_URL ??
  (process.env.NODE_ENV === "production" ? "" : "http://localhost:4010/api/v1");
