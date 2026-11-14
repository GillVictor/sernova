import { ApiError, NetworkError, type Problem } from "./errors";
import { routes, type Route } from "./routes";

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

export interface CurrentUser {
  user: { displayName?: string } & Record<string, unknown>;
  capacities?: unknown;
  providerStatus?: unknown;
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
  fetchImpl?: Fetch;
  /** Called when a refresh fails: the session is over. */
  onSessionLost?: () => void;
}

export class ApiClient {
  private tokens: TokenPair | null = null;
  private refreshing: Promise<boolean> | null = null;
  private readonly baseUrl: string;
  private readonly fetchImpl: Fetch;
  private readonly onSessionLost?: () => void;

  constructor(options: ApiClientOptions) {
    this.baseUrl = options.baseUrl.replace(/\/$/, "");
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
  me(): Promise<CurrentUser> {
    return this.send<CurrentUser>(routes.me, { auth: true });
  }

  // EP-021
  listCategories(): Promise<Category[]> {
    return this.send<Category[]>(routes.categories);
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

    if (auth && retry && response.status === 401 && code === "TOKEN_EXPIRED") {
      if (await this.refresh()) return this.send<T>(route, { ...opts, retry: false });
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

export const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:4010/api/v1";
