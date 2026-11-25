namespace ServNova.Api.Errors;

/// <summary>Stable error codes, taken from the "Erreurs" sheet of api-contract.xlsx.</summary>
public static class ErrorCodes
{
    public const string Unauthenticated = "UNAUTHENTICATED";
    public const string Forbidden = "FORBIDDEN";
    public const string NotFound = "NOT_FOUND";
    public const string RateLimited = "RATE_LIMITED";

    /// <summary>
    /// Provisional: the contract lists no code for an unexpected server error (OP-37).
    /// </summary>
    public const string InternalError = "INTERNAL_ERROR";
}
