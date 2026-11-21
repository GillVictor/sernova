export interface FieldError {
  field: string;
  code: string;
}

/** problem+json body (RFC 9457) as described in the contract, sheet "Conventions". */
export interface Problem {
  type?: string;
  title?: string;
  status?: number;
  code?: string;
  detail?: string;
  traceId?: string;
  errors?: FieldError[];
}

export class ApiError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    public readonly fieldErrors: FieldError[] = [],
    public readonly retryAfterSeconds?: number,
    public readonly traceId?: string,
  ) {
    super(code);
    this.name = "ApiError";
  }
}

/** Raised when the server cannot be reached at all. */
export class NetworkError extends Error {
  constructor() {
    super("NETWORK");
    this.name = "NetworkError";
  }
}

/** Raised when the API base URL is missing or not HTTPS in production. */
export class ConfigError extends Error {
  constructor() {
    super("CONFIG");
    this.name = "ConfigError";
  }
}
